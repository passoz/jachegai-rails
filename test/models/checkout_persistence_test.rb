require "test_helper"

class CheckoutPersistenceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "checkout-persistence@example.com", password: "password123", full_name: "Buyer")
    user.role_assignments.create!(role: "customer")
    @customer = user.customer
    @seller = Seller.create!(name: "Checkout Seller", moderation_state: "approved")
    category = Category.create!(seller: @seller, name: "Products", position: 1)
    @product = Product.create!(seller: @seller, category: category, name: "Original Name", price_cents: 500, currency: "BRL", active: true)
    @address = AddressService.create(customer: @customer, params: {
      name: "Home", line1: "Rua A", city: "São Paulo", state: "SP", zip: "01000-000", country: "BR"
    })
    @order = create_order
  end

  test "order stores authoritative monetary and address snapshots" do
    item = @order.order_items.create!(
      product: @product, seller: @seller, product_name: @product.name,
      quantity: 2, unit_price_cents: 500, subtotal_cents: 1_000, currency: "BRL"
    )
    @product.update!(name: "Changed", price_cents: 900)
    @address.update!(line1: "Rua B")

    assert_equal "Original Name", item.reload.product_name
    assert_equal 500, item.unit_price_cents
    assert_equal "Rua A", @order.reload.address_line1
    assert_equal 1_000, @order.total_cents
  end

  test "order and payment authoritative snapshots are readonly after creation" do
    payment = @order.create_payment!(state: "pending", amount_cents: 1_000, currency: "BRL")

    assert_raises ActiveRecord::ReadonlyAttributeError do
      @order.update!(address_line1: "Changed", total_cents: 2_000)
    end
    assert_raises ActiveRecord::ReadonlyAttributeError do
      payment.update!(amount_cents: 2_000, currency: "USD")
    end

    assert_equal "Rua A", @order.reload.address_line1
    assert_equal 1_000, @order.total_cents
    assert_equal 1_000, payment.reload.amount_cents
    assert_equal "BRL", payment.currency
  end

  test "database rejects inconsistent totals invalid states and invalid item subtotals" do
    assert_raises ActiveRecord::StatementInvalid do
      Order.insert_all!([ order_insert_attributes.merge(id: ApplicationId.generate, total_cents: 999) ])
    end
    assert_raises ActiveRecord::StatementInvalid do
      Order.insert_all!([ order_insert_attributes.merge(id: ApplicationId.generate, status: "unknown") ])
    end
    assert_raises ActiveRecord::StatementInvalid do
      OrderItem.insert_all!([ {
        id: ApplicationId.generate, order_id: @order.id, product_id: @product.id, seller_id: @seller.id,
        product_name: "Snapshot", quantity: 2, unit_price_cents: 500, subtotal_cents: 999,
        currency: "BRL", created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "enforces exactly one payment per order and unique external reference" do
    first = @order.create_payment!(state: "pending", amount_cents: 1_000, currency: "BRL")
    other_order = create_order

    assert_raises ActiveRecord::RecordNotUnique do
      Payment.insert_all!([ first.attributes.except("id").merge("id" => ApplicationId.generate) ])
    end
    other_order.create_payment!(state: "pending", amount_cents: 1_000, currency: "BRL", external_reference: "sim-1")
    assert_raises ActiveRecord::RecordNotUnique do
      Payment.insert_all!([ {
        id: ApplicationId.generate, order_id: create_order.id, state: "pending", method: "simulated",
        provider: "simulated", external_reference: "sim-1", amount_cents: 1_000, currency: "BRL",
        created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "history snapshots and inventory movements are append-only" do
    history = @order.order_status_histories.create!(
      from_status: nil, to_status: "pending", actor_principal_id: @customer.user_id,
      occurred_at: Time.current
    )
    movement = @order.inventory_movements.create!(
      product: @product, seller: @seller, kind: "checkout_decrement", quantity: 1, balance_after: 9
    )

    refute history.update(reason: "changed")
    refute history.destroy
    refute movement.update(quantity: 2)
    refute movement.destroy
  end

  test "database rejects seller mismatch in order items and inventory movements" do
    other_seller = Seller.create!(name: "Other Seller", moderation_state: "approved")

    assert_raises ActiveRecord::InvalidForeignKey do
      OrderItem.insert_all!([ {
        id: ApplicationId.generate, order_id: @order.id, product_id: @product.id, seller_id: other_seller.id,
        product_name: "Snapshot", quantity: 1, unit_price_cents: 500, subtotal_cents: 500,
        currency: "BRL", created_at: Time.current, updated_at: Time.current
      } ])
    end
    assert_raises ActiveRecord::InvalidForeignKey do
      InventoryMovement.insert_all!([ {
        id: ApplicationId.generate, order_id: @order.id, product_id: @product.id, seller_id: other_seller.id,
        kind: "checkout_decrement", quantity: 1, balance_after: 9,
        created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "movement idempotency idempotency key and outbox key are unique" do
    @order.inventory_movements.create!(product: @product, seller: @seller, kind: "checkout_decrement", quantity: 1, balance_after: 9)
    assert_raises ActiveRecord::RecordNotUnique do
      InventoryMovement.insert_all!([ {
        id: ApplicationId.generate, order_id: @order.id, product_id: @product.id, seller_id: @seller.id,
        kind: "checkout_decrement", quantity: 1, balance_after: 8, created_at: Time.current, updated_at: Time.current
      } ])
    end

    attrs = { principal_id: @customer.id, operation: "checkout", key: "key-1", request_digest: "digest", state: "processing" }
    IdempotencyRecord.create!(attrs)
    assert_raises ActiveRecord::RecordNotUnique do
      IdempotencyRecord.insert_all!([ attrs.merge(id: ApplicationId.generate, created_at: Time.current, updated_at: Time.current) ])
    end

    event = { event_key: "order:#{@order.id}:created", event_type: "order.created", aggregate_type: "Order", aggregate_id: @order.id, payload: "{}", available_at: Time.current }
    OutboxEvent.create!(event)
    assert_raises ActiveRecord::RecordNotUnique do
      OutboxEvent.insert_all!([ event.merge(id: ApplicationId.generate, state: "pending", attempts: 0, max_attempts: 10, created_at: Time.current, updated_at: Time.current) ])
    end
  end

  private

  def create_order
    Order.create!(order_attributes)
  end

  def order_insert_attributes
    order_attributes.except(:customer, :seller, :source_address).merge(
      customer_id: @customer.id,
      seller_id: @seller.id,
      source_address_id: @address.id
    )
  end

  def order_attributes
    {
      customer: @customer, seller: @seller, source_address: @address, status: "pending", currency: "BRL",
      subtotal_cents: 1_000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0, total_cents: 1_000,
      address_name: @address.name, address_line1: @address.line1, address_city: @address.city,
      address_state: @address.state, address_zip: @address.zip, address_country: @address.country,
      created_at: Time.current, updated_at: Time.current
    }
  end
end
