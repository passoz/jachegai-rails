require "test_helper"

class OrderTransitionServiceTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer = Customer.create!(user: @customer_user, full_name: "Buyer")
    @seller_user = User.create!(email: "merchant@example.com", password: "password123", full_name: "Merchant")
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")

    @product = Product.create!(
      seller: @seller, name: "Pizza", price_cents: 1000, currency: "BRL",
      active: true, category: Category.create!(seller: @seller, name: "Food", position: 1)
    )
    @inventory = InventoryItem.create!(product: @product, seller: @seller, quantity: 10)

    @address = Address.create!(
      customer: @customer, name: "Home", line1: "123 Main St", city: "City",
      state: "ST", zip: "12345", country: "BR", is_default: true
    )

    @order = Order.create!(
      customer: @customer, seller: @seller, source_address: @address,
      status: "pending", currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 0,
      discount_cents: 0, courier_fee_cents: 0, total_cents: 1000,
      address_name: "Home", address_line1: "123 Main St", address_city: "City",
      address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @payment = Payment.create!(
      order: @order, state: "pending", amount_cents: 1000, currency: "BRL"
    )

    @seller_principal = Principal.new(user: @seller_user)
  end

  test "atomic transition records history and outbox event" do
    @payment.update!(state: "paid")

    service = OrderTransitionService.new(@order, actor: @seller_principal)
    assert_difference -> { OrderStatusHistory.count } => 1, -> { OutboxEvent.count } => 1 do
      service.transition_to!("accepted", reason: "Accepted by merchant", request_id: "req-123")
    end

    assert_equal "accepted", @order.reload.status
    history = @order.order_status_histories.last
    assert_equal "pending", history.from_status
    assert_equal "accepted", history.to_status
    assert_equal "user:#{@seller_user.id}", history.actor_principal_id
    assert_equal "Accepted by merchant", history.reason
    assert_equal "req-123", history.request_id

    event = OutboxEvent.last
    assert_equal "order.accepted", event.event_type
    assert_equal "Order", event.aggregate_type
    assert_equal @order.id, event.aggregate_id
    payload = JSON.parse(event.payload)
    assert_equal "accepted", payload["status"]
  end

  test "transition rolls back status and history when outbox persistence fails" do
    @payment.update!(state: "paid")
    event_key = "order:#{@order.id}:transition:pending_to_accepted"
    OutboxEvent.create!(
      event_key: event_key,
      event_type: "probe.conflict",
      aggregate_type: "Probe",
      aggregate_id: @order.id,
      payload: "{}",
      available_at: Time.current
    )
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    assert_raises ActiveRecord::RecordInvalid do
      service.transition_to!("accepted", request_id: "req-rollback")
    end

    assert_equal "pending", @order.reload.status
    assert_empty @order.order_status_histories
    assert_equal 1, OutboxEvent.where(event_key: event_key).count
  end

  test "accept transition requires payment state paid" do
    service = OrderTransitionService.new(@order, actor: @seller_principal)
    err = assert_raises DomainError do
      service.transition_to!("accepted")
    end
    assert_equal "payment_required", err.code
    assert_equal "pending", @order.reload.status
  end

  test "seller cannot transition orders belonging to another seller" do
    other_seller = Seller.create!(name: "Other Store", moderation_state: "approved")
    other_user = User.create!(email: "other@example.com", password: "password123", full_name: "Other")
    other_user.role_assignments.create!(role: "seller")
    other_user.seller_memberships.create!(seller: other_seller, role: "owner")
    other_principal = Principal.new(user: other_user)

    service = OrderTransitionService.new(@order, actor: other_principal)
    assert_raises ActiveRecord::RecordNotFound do
      service.transition_to!("accepted")
    end
  end

  test "invalid state machine transition throws domain error" do
    @payment.update!(state: "paid")
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    err = assert_raises DomainError do
      service.transition_to!("ready") # Jump steps pending -> ready
    end
    assert_equal "invalid_transition", err.code
  end

  test "owning seller cannot perform courier-only transitions" do
    @order.update!(status: "ready")
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    error = assert_raises DomainError do
      service.transition_to!("assigned")
    end

    assert_equal "forbidden_transition", error.code
    assert_equal "ready", @order.reload.status
    assert_empty @order.order_status_histories
  end

  test "idempotent no-op cannot bypass actor capability" do
    @order.update!(status: "assigned")
    service = OrderTransitionService.new(@order, actor: @seller_principal)

    error = assert_raises DomainError do
      service.transition_to!("assigned")
    end

    assert_equal "forbidden_transition", error.code
    assert_empty @order.order_status_histories
  end
end
