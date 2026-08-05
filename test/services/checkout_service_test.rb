require "test_helper"

class CheckoutServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "checkout@example.com", password: "password123", full_name: "Buyer")
    @user.role_assignments.create!(role: "customer")
    @customer = @user.customer
    @seller = Seller.create!(name: "Checkout Seller", moderation_state: "approved")
    category = Category.create!(seller: @seller, name: "Products", position: 1)
    @product = Product.create!(seller: @seller, category: category, name: "Authoritative Product", price_cents: 750, currency: "BRL", active: true)
    @inventory = InventoryItem.create!(seller: @seller, product: @product, quantity: 5)
    @address = AddressService.create(customer: @customer, params: {
      name: "Home", line1: "Rua Checkout", city: "São Paulo", state: "SP", zip: "01000-000", country: "BR"
    })
    @cart = CustomerCartService.add_item(customer: @customer, product_id: @product.id, quantity: 2)
  end

  test "atomically creates order snapshots history payment movement outbox and clears cart" do
    order = checkout(key: "success")

    assert_equal "pending", order.status
    assert_equal @customer.id, order.customer_id
    assert_equal @seller.id, order.seller_id
    assert_equal 1_500, order.subtotal_cents
    assert_equal 0, order.delivery_fee_cents
    assert_equal 0, order.discount_cents
    assert_equal 0, order.courier_fee_cents
    assert_equal 1_500, order.total_cents
    assert_equal "BRL", order.currency
    assert_equal "Rua Checkout", order.address_line1

    item = order.order_items.sole
    assert_equal "Authoritative Product", item.product_name
    assert_equal 750, item.unit_price_cents
    assert_equal 2, item.quantity
    assert_equal 1_500, item.subtotal_cents

    history = order.order_status_histories.sole
    assert_nil history.from_status
    assert_equal "pending", history.to_status
    assert_equal @user.id, history.actor_principal_id

    payment = order.payment
    assert_equal "pending", payment.state
    assert_equal order.total_cents, payment.amount_cents
    assert_equal order.currency, payment.currency
    assert_equal "simulated", payment.provider

    movement = order.inventory_movements.sole
    assert_equal "checkout_decrement", movement.kind
    assert_equal 2, movement.quantity
    assert_equal 3, movement.balance_after
    assert_equal 3, @inventory.reload.quantity

    event = OutboxEvent.find_by!(aggregate_id: order.id)
    assert_equal "order.created", event.event_type
    assert_equal "pending", event.state
    assert_equal 0, event.attempts

    assert_empty @cart.reload.cart_items
    assert_nil @cart.seller_id
    assert_equal "completed", IdempotencyRecord.find_by!(key: "success").state
  end

  test "retry with same key returns original order without repeating effects" do
    first = checkout(key: "retry")
    second = checkout(key: "retry")

    assert_equal first.id, second.id
    assert_equal 1, Order.where(customer: @customer).count
    assert_equal 1, Payment.where(order: first).count
    assert_equal 1, InventoryMovement.where(order: first).count
    assert_equal 3, @inventory.reload.quantity
  end

  test "address must belong to the customer without disclosure" do
    other_user = User.create!(email: "other-address-checkout@example.com", password: "password123", full_name: "Other")
    other_user.role_assignments.create!(role: "customer")
    other_address = AddressService.create(customer: other_user.customer, params: {
      name: "Other", line1: "Rua Other", city: "São Paulo", state: "SP", zip: "02000-000", country: "BR"
    })

    assert_raises ActiveRecord::RecordNotFound do
      checkout(key: "other-address", address_id: other_address.id)
    end
    assert_no_business_records
    assert_equal 5, @inventory.reload.quantity
    assert_equal 1, @cart.reload.cart_items.count
  end

  test "revalidates seller product quantity and inventory authoritatively" do
    @seller.update!(moderation_state: "suspended")

    error = assert_raises(DomainError) { checkout(key: "ineligible") }
    assert_equal "invalid_input", error.code
    assert_no_business_records
    assert_equal 1, @cart.reload.cart_items.count
  end

  test "insufficient inventory has stable error and no partial state" do
    @inventory.update!(quantity: 1)

    error = assert_raises(DomainError) { checkout(key: "stock") }
    assert_equal "insufficient_inventory", error.code
    assert_equal @product.id, error.as_json.dig(:context, :product_id)
    assert_no_business_records
    assert_equal 1, @inventory.reload.quantity
    assert_equal 1, @cart.reload.cart_items.count
  end

  test "provider failure rolls back local state and leaves retryable cart and idempotency failure" do
    error = assert_raises(DomainError) do
      checkout(key: "provider-failure", gateway: Payments::SimulatedGateway.new(failure: :unavailable))
    end

    assert_equal "external_dependency_unavailable", error.code
    assert_no_business_records
    assert_equal 5, @inventory.reload.quantity
    assert_equal 1, @cart.reload.cart_items.count
    record = IdempotencyRecord.find_by!(key: "provider-failure")
    assert_equal "failed", record.state
    assert_equal "external_dependency_unavailable", record.last_error_code
  end

  test "gateway amount mismatch rolls back all local effects" do
    wrong_gateway = Class.new(Payments::Gateway) do
      def create(command)
        Payments::Intent.new(
          state: "pending",
          provider: "wrong",
          method: "simulated",
          external_reference: "wrong-reference",
          amount: Money.new(cents: command.amount.cents + 1, currency: command.amount.currency)
        )
      end
    end.new

    error = assert_raises(DomainError) { checkout(key: "wrong-amount", gateway: wrong_gateway) }

    assert_equal "external_dependency_unavailable", error.code
    assert_no_business_records
    assert_equal 5, @inventory.reload.quantity
    assert_equal 1, @cart.reload.cart_items.count
  end

  test "catalog and address changes after checkout do not alter snapshots" do
    order = checkout(key: "snapshots")
    @product.update!(name: "Changed", price_cents: 9_999)
    AddressService.destroy(address: @address)

    assert_equal "Authoritative Product", order.order_items.sole.reload.product_name
    assert_equal 750, order.order_items.sole.unit_price_cents
    assert_nil order.reload.source_address_id
    assert_equal "Rua Checkout", order.address_line1
    assert_equal 1_500, order.total_cents
  end

  private

  def checkout(key:, address_id: @address.id, gateway: Payments::SimulatedGateway.new)
    CheckoutService.new(payment_gateway: gateway).call(
      customer: @customer,
      address_id: address_id,
      idempotency_key: key,
      actor_principal_id: @user.id,
      request_id: "request-#{key}"
    )
  end

  def assert_no_business_records
    assert_equal 0, Order.count
    assert_equal 0, Payment.count
    assert_equal 0, InventoryMovement.count
    assert_equal 0, OutboxEvent.count
  end
end
