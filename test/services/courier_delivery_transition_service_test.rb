require "test_helper"

class CourierDeliveryTransitionServiceTest < ActiveSupport::TestCase
  setup do
    @courier_user = User.create!(
      email: "courier.delivery@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Delivery"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511988889999",
      document_number: "88899900011",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "on_delivery"
    )
    @principal = Principal.new(user: @courier_user, session: Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test"))

    # Other courier
    @other_user = User.create!(
      email: "other.courier@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Other Courier"
    )
    @other_user.role_assignments.create!(role: "courier")
    @other_courier = Courier.create!(
      user: @other_user,
      phone: "+5511977778888",
      document_number: "77788899900",
      vehicle_type: "bicycle",
      moderation_state: "approved",
      operational_state: "available"
    )
    @other_principal = Principal.new(user: @other_user, session: Session.issue_for(@other_user, ip: "127.0.0.1", user_agent: "Test"))

    # Seller & Customer & Order
    @seller_user = User.create!(
      email: "seller.deliv@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Seller Deliv"
    )
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "Deliv Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")

    @customer_user = User.create!(
      email: "customer.deliv@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Customer Deliv"
    )
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer || Customer.create!(user: @customer_user, full_name: @customer_user.full_name)

    @order = Order.create!(
      customer: @customer,
      seller: @seller,
      courier: @courier,
      status: "assigned",
      subtotal_cents: 2000,
      delivery_fee_cents: 500,
      total_cents: 2500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua D, 101",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end

  test "assigned courier advances order from assigned to picked_up with atomic evidence" do
    service = CourierDeliveryTransitionService.new(@principal)
    updated = service.pickup!(@order.id, request_id: "pickup-request")

    assert_equal "picked_up", updated.status
    assert_equal "on_delivery", @courier.reload.operational_state
    history = OrderStatusHistory.find_by!(order_id: @order.id, to_status: "picked_up")
    assert_equal "assigned", history.from_status
    assert_equal "user:#{@courier_user.id}", history.actor_principal_id
    assert_equal "pickup-request", history.request_id
    assert history.occurred_at.present?
    event = OutboxEvent.find_by!(aggregate_id: @order.id, event_type: "order.picked_up")
    payload = JSON.parse(event.payload)
    assert_equal "assigned", payload["from_status"]
    assert_equal "picked_up", payload["to_status"]
  end

  test "assigned courier advances order from picked_up to delivered and becomes available" do
    @order.update!(status: "picked_up")
    service = CourierDeliveryTransitionService.new(@principal)
    updated = service.deliver!(@order.id)

    assert_equal "delivered", updated.status
    assert_equal "available", @courier.reload.operational_state

    history = OrderStatusHistory.last
    assert_equal "picked_up", history.from_status
    assert_equal "delivered", history.to_status
  end

  test "suspended assigned courier can finish existing delivery but remains offline" do
    @order.update!(status: "picked_up")
    @courier.update!(moderation_state: "suspended", operational_state: "offline")

    updated = CourierDeliveryTransitionService.new(@principal).deliver!(@order.id)

    assert_equal "delivered", updated.status
    assert_equal "offline", @courier.reload.operational_state
  end

  test "unassigned courier fails closed without order disclosure" do
    service = CourierDeliveryTransitionService.new(@other_principal)

    assert_raises ActiveRecord::RecordNotFound do
      service.pickup!(@order.id)
    end
    assert_equal "assigned", @order.reload.status
  end

  test "principal without courier role cannot transition assigned order" do
    @courier_user.role_assignments.where(role: "courier").delete_all

    error = assert_raises DomainError do
      CourierDeliveryTransitionService.new(@principal).pickup!(@order.id)
    end

    assert_equal "forbidden", error.code
    assert_equal "assigned", @order.reload.status
  end

  test "retry of same transition does not duplicate history or event" do
    service = CourierDeliveryTransitionService.new(@principal)
    service.pickup!(@order.id)
    counts = [ OrderStatusHistory.count, OutboxEvent.count ]

    service.pickup!(@order.id)

    assert_equal counts, [ OrderStatusHistory.count, OutboxEvent.count ]
  end

  test "outbox failure rolls order courier state and history back" do
    event_key = "order:#{@order.id}:transition:assigned_to_picked_up"
    OutboxEvent.create!(
      event_key: event_key,
      event_type: "probe.conflict",
      aggregate_type: "Probe",
      aggregate_id: @order.id,
      payload: "{}",
      available_at: Time.current
    )

    assert_raises ActiveRecord::RecordInvalid do
      CourierDeliveryTransitionService.new(@principal).pickup!(@order.id)
    end

    assert_equal "assigned", @order.reload.status
    assert_equal "on_delivery", @courier.reload.operational_state
    assert_empty OrderStatusHistory.where(order_id: @order.id)
    assert_equal 1, OutboxEvent.where(event_key: event_key).count
  end
end
