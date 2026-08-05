require "test_helper"

class OrderCancellationServiceTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer
    @customer_principal = Principal.new(user: @customer_user)

    @seller_user = User.create!(email: "merchant@example.com", password: "password123", full_name: "Merchant")
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")
    @seller_principal = Principal.new(user: @seller_user)

    @admin_user = User.create!(email: "admin@example.com", password: "password123", full_name: "Admin")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_principal = Principal.new(user: @admin_user)

    @product = Product.create!(
      seller: @seller, name: "Pizza", price_cents: 1000, currency: "BRL",
      active: true, category: Category.create!(seller: @seller, name: "Food", position: 1)
    )
    @inventory = InventoryItem.create!(product: @product, seller: @seller, quantity: 10)

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @order.order_items.create!(
      product: @product, seller: @seller, product_name: "Pizza",
      quantity: 2, unit_price_cents: 500, subtotal_cents: 1000, currency: "BRL"
    )

    # Decremento inicial simulando checkout
    @inventory.decrement!(:quantity, 2)

    @payment = Payment.create!(
      order: @order, state: "pending", amount_cents: 1000, currency: "BRL"
    )
  end

  test "seller reject restores inventory and updates payment state to failed" do
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    assert_difference -> { InventoryMovement.count } => 1 do
      service.transition_to!("rejected", reason: "Out of dough")
    end

    assert_equal "rejected", @order.reload.status
    assert_equal 10, @inventory.reload.quantity # 8 + 2
    assert_equal "failed", @payment.reload.state
    assert_equal "order_rejected", @payment.last_error_code

    movement = InventoryMovement.last
    assert_equal "restore", movement.kind
    assert_equal 2, movement.quantity
    assert_equal 10, movement.balance_after
  end

  test "customer cancel requires reason and updates payment to failed" do
    service = OrderTransitionService.new(@order, actor: @customer_principal)

    # Reason is required for customer
    err = assert_raises DomainError do
      service.transition_to!("cancelled")
    end
    assert_equal "reason_required", err.code

    assert_difference -> { InventoryMovement.count } => 1 do
      service.transition_to!("cancelled", reason: "Changed my mind")
    end

    assert_equal "cancelled", @order.reload.status
    assert_equal 10, @inventory.reload.quantity
    assert_equal "failed", @payment.reload.state
    assert_equal "order_cancelled", @payment.last_error_code
  end

  test "customer cannot cancel accepted order" do
    @order.update!(status: "accepted")
    service = OrderTransitionService.new(@order, actor: @customer_principal)

    assert_raises DomainError do
      service.transition_to!("cancelled", reason: "Too late")
    end
  end

  test "customer cannot cancel unless payment is pending" do
    @payment.update!(state: "failed")
    service = OrderTransitionService.new(@order, actor: @customer_principal)

    error = assert_raises DomainError do
      service.transition_to!("cancelled", reason: "Payment already failed")
    end

    assert_equal "payment_conflict", error.code
    assert_equal "pending", @order.reload.status
    assert_equal 8, @inventory.reload.quantity
  end

  test "admin can cancel accepted order if payment is not paid" do
    @order.update!(status: "accepted")
    service = OrderTransitionService.new(@order, actor: @admin_principal)

    service.transition_to!("cancelled", reason: "Admin intervention")
    assert_equal "cancelled", @order.reload.status
    assert_equal 10, @inventory.reload.quantity
    assert_equal "failed", @payment.reload.state
  end

  test "admin capability takes precedence when the actor also has seller and customer roles" do
    @admin_user.role_assignments.create!(role: "seller")
    @admin_user.role_assignments.create!(role: "customer")
    other_seller = Seller.create!(name: "Admin Membership Store", moderation_state: "approved")
    @admin_user.seller_memberships.create!(seller: other_seller, role: "owner")
    @order.update!(status: "accepted")
    service = OrderTransitionService.new(@order, actor: @admin_principal)

    service.transition_to!("cancelled", reason: "Administrative policy")

    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.state
  end

  test "admin cancellation of assigned order releases approved courier" do
    courier = create_assigned_courier
    @order.update!(status: "assigned", courier: courier)
    service = OrderTransitionService.new(@order, actor: @admin_principal)

    service.transition_to!("cancelled", reason: "Courier unavailable")

    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.state
    assert_equal 10, @inventory.reload.quantity
    assert_equal "available", courier.reload.operational_state
  end

  test "admin cancellation of assigned order keeps suspended courier offline" do
    courier = create_assigned_courier
    @order.update!(status: "assigned", courier: courier)
    courier.update!(moderation_state: "suspended", operational_state: "offline")

    OrderTransitionService.new(@order, actor: @admin_principal).transition_to!("cancelled", reason: "Courier suspended")

    assert_equal "cancelled", @order.reload.status
    assert_equal "offline", courier.reload.operational_state
  end

  test "cancellation outbox failure rolls assigned courier release back" do
    courier = create_assigned_courier
    @order.update!(status: "assigned", courier: courier)
    event_key = "order:#{@order.id}:transition:assigned_to_cancelled"
    OutboxEvent.create!(
      event_key: event_key,
      event_type: "probe.conflict",
      aggregate_type: "Probe",
      aggregate_id: @order.id,
      payload: "{}",
      available_at: Time.current
    )

    assert_raises ActiveRecord::RecordInvalid do
      OrderTransitionService.new(@order, actor: @admin_principal).transition_to!("cancelled", reason: "Rollback probe")
    end

    assert_equal "assigned", @order.reload.status
    assert_equal "on_delivery", courier.reload.operational_state
    assert_equal "pending", @payment.reload.state
    assert_equal 8, @inventory.reload.quantity
  end

  test "admin cannot use the customer or expiration pending cancellation window" do
    service = OrderTransitionService.new(@order, actor: @admin_principal)

    error = assert_raises DomainError do
      service.transition_to!("cancelled", reason: "Wrong cancellation window")
    end

    assert_equal "forbidden_transition", error.code
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
    assert_equal 8, @inventory.reload.quantity
  end

  test "cannot cancel paid order without refund capability" do
    @payment.update!(state: "paid")
    service = OrderTransitionService.new(@order, actor: @admin_principal)

    err = assert_raises DomainError do
      service.transition_to!("cancelled", reason: "Paid order cancellation")
    end
    assert_equal "refund_required", err.code
  end

  test "seller cannot reject a paid order without refund capability" do
    @payment.update!(state: "paid")
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    error = assert_raises DomainError do
      service.transition_to!("rejected", reason: "Cannot fulfill")
    end

    assert_equal "refund_required", error.code
    assert_equal "pending", @order.reload.status
    assert_equal "paid", @payment.reload.state
    assert_equal 8, @inventory.reload.quantity
  end

  test "customer capability is selected for cancellation when actor also has seller role" do
    @customer_user.role_assignments.create!(role: "seller")
    customer_seller = Seller.create!(name: "Buyer Side Store", moderation_state: "approved")
    @customer_user.seller_memberships.create!(seller: customer_seller, role: "owner")
    service = OrderTransitionService.new(@order, actor: @customer_principal)

    service.transition_to!("cancelled", reason: "Changed my mind")

    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.state
  end

  test "seller retry remains idempotent when actor also has customer role" do
    @seller_user.role_assignments.create!(role: "customer")
    service = OrderTransitionService.new(@order, actor: @seller_principal)
    service.transition_to!("rejected", reason: "Unavailable")
    counts = [ InventoryMovement.count, OrderStatusHistory.count, OutboxEvent.count ]

    service.transition_to!("rejected", reason: "Unavailable")

    assert_equal counts, [ InventoryMovement.count, OrderStatusHistory.count, OutboxEvent.count ]
    assert_equal "rejected", @order.reload.status
  end

  test "inventory restore is idempotent and does not duplicate movements on retry" do
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    service.transition_to!("rejected", reason: "Out of dough")
    assert_equal 10, @inventory.reload.quantity

    # Re-running the service for the same target state is a no-op
    assert_no_difference -> { InventoryMovement.count } do
      service.transition_to!("rejected", reason: "Out of dough")
    end

    assert_equal 10, @inventory.reload.quantity
  end

  test "customer retry still validates the mandatory cancellation reason" do
    service = OrderTransitionService.new(@order, actor: @customer_principal)
    service.transition_to!("cancelled", reason: "Changed my mind")

    error = assert_raises DomainError do
      service.transition_to!("cancelled")
    end

    assert_equal "reason_required", error.code
    assert_equal "cancelled", @order.reload.status
  end

  private

  def create_assigned_courier
    user = User.create!(email: "assigned-courier@example.com", password: "password123", full_name: "Assigned Courier")
    user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: user,
      phone: "+5511888877777",
      document_number: "88777766655",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "on_delivery"
    )
  end
end
