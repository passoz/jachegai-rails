require "test_helper"

class CourierAssignmentServiceTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    cleanup_tables
    @courier1 = create_courier(index: 1)
    @courier2 = create_courier(index: 2)
    @principal1 = Principal.new(user: @courier1.user)
    @principal2 = Principal.new(user: @courier2.user)
    @order = create_ready_order
  end

  teardown do
    cleanup_tables
  end

  test "courier must be both approved and available to accept an order" do
    @courier1.update!(operational_state: "offline")

    error = assert_raises DomainError do
      CourierAssignmentService.new(@principal1).accept_order!(
        @order.id,
        idempotency_key: "offline-courier"
      )
    end

    assert_equal "courier_not_available", error.code
    assert_equal "ready", @order.reload.status
    assert_nil @order.courier_id
  end

  test "two real connections concurrently accepting one order produce one complete assignment" do
    ready = Queue.new
    start = Queue.new
    principals = [ @principal1, @principal2 ]

    threads = principals.map.with_index do |principal, index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          begin
            order = CourierAssignmentService.new(principal).accept_order!(
              @order.id,
              idempotency_key: "concurrent-assignment-#{index}",
              request_id: "assignment-request-#{index}"
            )
            [ :success, order.courier_id ]
          rescue DomainError => error
            [ :domain_error, error.code ]
          end
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    results = threads.map(&:value)

    assert_equal 1, results.count { |kind, _| kind == :success }
    assert_equal 1, results.count { |kind, code| kind == :domain_error && code == "order_already_assigned" }

    assigned_order = @order.reload
    winner = Courier.find(assigned_order.courier_id)
    loser = [ @courier1, @courier2 ].find { |courier| courier.id != winner.id }
    assert_equal "assigned", assigned_order.status
    assert_equal "on_delivery", winner.reload.operational_state
    assert_equal "available", loser.reload.operational_state
    assert_equal assigned_order.id, Order.find_by(courier_id: winner.id, status: %w[assigned picked_up])&.id
    assert_nil Order.find_by(courier_id: loser.id, status: %w[assigned picked_up])
    assert_equal 1, OrderStatusHistory.where(order_id: @order.id, from_status: "ready", to_status: "assigned").count
    assert_equal 1, OutboxEvent.where(aggregate_type: "Order", aggregate_id: @order.id, event_type: "order.assigned").count
    assert_equal 1, IdempotencyRecord.where(operation: CourierAssignmentService::OPERATION, state: "completed").count
    assert_equal 1, IdempotencyRecord.where(operation: CourierAssignmentService::OPERATION, state: "failed").count
  end

  test "outbox failure rolls back assignment courier state history and idempotency completion" do
    event_key = "order:#{@order.id}:transition:ready_to_assigned"
    OutboxEvent.create!(
      event_key: event_key,
      event_type: "probe.conflict",
      aggregate_type: "Probe",
      aggregate_id: @order.id,
      payload: "{}",
      available_at: Time.current
    )

    assert_raises ActiveRecord::RecordInvalid do
      CourierAssignmentService.new(@principal1).accept_order!(
        @order.id,
        idempotency_key: "rollback-assignment"
      )
    end

    assert_equal "ready", @order.reload.status
    assert_nil @order.courier_id
    assert_equal "available", @courier1.reload.operational_state
    assert_empty OrderStatusHistory.where(order_id: @order.id)
    assert_equal 1, OutboxEvent.where(event_key: event_key).count
    record = IdempotencyRecord.find_by!(
      principal_id: @courier1.user_id,
      operation: CourierAssignmentService::OPERATION,
      key: "rollback-assignment"
    )
    assert_equal "failed", record.state
    assert_nil record.resource_id
  end

  private

  def create_courier(index:)
    user = User.create!(email: "courier-assign-#{index}@example.com", password: "password123", full_name: "Courier #{index}")
    user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: user,
      phone: "+55119000000#{index}",
      document_number: index.to_s.rjust(11, "0"),
      vehicle_type: index == 1 ? "motorcycle" : "bicycle",
      moderation_state: "approved",
      operational_state: "available"
    )
  end

  def create_ready_order
    seller = Seller.create!(name: "Assignment Store", moderation_state: "approved")
    customer_user = User.create!(email: "assignment-customer@example.com", password: "password123", full_name: "Customer")
    customer_user.role_assignments.create!(role: "customer")

    Order.create!(
      customer: customer_user.customer,
      seller: seller,
      status: "ready",
      subtotal_cents: 2_000,
      delivery_fee_cents: 500,
      total_cents: 2_500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua B, 456",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end

  def cleanup_tables
    [ OutboxEvent, InventoryMovement, Payment, OrderStatusHistory, OrderItem, IdempotencyRecord, Order,
      CartItem, Cart, Address, Favorite, InventoryItem, Product, Category, SellerSettings, SellerMembership,
      Seller, Courier, Customer, RoleAssignment, Session, User ].each(&:delete_all)
  end
end
