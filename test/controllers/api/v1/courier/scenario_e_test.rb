require "test_helper"

class Api::V1::Courier::ScenarioETest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    cleanup_tables
    @couriers = [ create_courier(1), create_courier(2) ]
    @tokens = @couriers.map { |courier| Session.issue_for(courier.user) }
    @order = create_ready_order
  end

  teardown do
    cleanup_tables
  end

  test "two visible eligible couriers concurrently accept and exactly one sees active delivery" do
    @tokens.each do |token|
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.get("/api/v1/courier/orders/eligible", headers: auth(token))
      assert_equal 200, session.response.status
      eligible_ids = JSON.parse(session.response.body).fetch("data").pluck("id")
      assert_includes eligible_ids, @order.id
    end

    ready = Queue.new
    start = Queue.new
    threads = @tokens.map.with_index do |token, index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          session = ActionDispatch::Integration::Session.new(Rails.application)
          ready << true
          start.pop
          session.post(
            "/api/v1/courier/orders/#{@order.id}/accept",
            headers: auth(token).merge("Idempotency-Key" => "scenario-e-#{index}")
          )
          [ session.response.status, JSON.parse(session.response.body) ]
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    results = threads.map(&:value)

    assert_equal 1, results.count { |status, _| status == 200 }
    assert_equal 1, results.count { |status, body| status == 409 && body.dig("error", "code") == "order_already_assigned" }

    assigned_order = @order.reload
    winner_index = @couriers.index { |courier| courier.id == assigned_order.courier_id }
    loser_index = winner_index.zero? ? 1 : 0
    assert_equal "assigned", assigned_order.status

    winner_session = ActionDispatch::Integration::Session.new(Rails.application)
    winner_session.get("/api/v1/courier/orders/active", headers: auth(@tokens.fetch(winner_index)))
    assert_equal 200, winner_session.response.status
    assert_equal @order.id, JSON.parse(winner_session.response.body).dig("data", "id")

    loser_session = ActionDispatch::Integration::Session.new(Rails.application)
    loser_session.get("/api/v1/courier/orders/active", headers: auth(@tokens.fetch(loser_index)))
    assert_equal 200, loser_session.response.status
    assert_nil JSON.parse(loser_session.response.body)["data"]

    assert_equal 1, OrderStatusHistory.where(order_id: @order.id, from_status: "ready", to_status: "assigned").count
    assert_equal 1, OutboxEvent.where(aggregate_type: "Order", aggregate_id: @order.id, event_type: "order.assigned").count
  end

  private

  def auth(token)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end

  def create_courier(index)
    user = User.create!(email: "scenario-e-courier-#{index}@example.com", password: "password123", full_name: "Courier #{index}")
    user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: user,
      phone: "+55118888800#{index.to_s.rjust(2, "0")}",
      document_number: (888_000_888_00 + index).to_s,
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "available"
    )
  end

  def create_ready_order
    seller = Seller.create!(name: "Scenario E Store", moderation_state: "approved")
    customer_user = User.create!(email: "scenario-e-customer@example.com", password: "password123", full_name: "Customer")
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
      address_line1: "Rua E, 1",
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
