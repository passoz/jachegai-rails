require "test_helper"

class Api::V1::Courier::ScenarioFTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    cleanup_tables
    @courier_user = User.create!(email: "scenario.f.courier@example.com", password: "password123", full_name: "Courier F")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511999991111", document_number: "99911122233",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available",
      location_consent_given_at: Time.current
    )
    @courier_token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    @customer_user = User.create!(email: "scenario.f.customer@example.com", password: "password123", full_name: "Customer F")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer
    @customer_token = Session.issue_for(@customer_user, ip: "127.0.0.1", user_agent: "Test")

    @seller = Seller.create!(name: "Scenario F Store", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "ready", currency: "BRL",
      subtotal_cents: 3000, delivery_fee_cents: 500, total_cents: 3500,
      address_name: "Home", address_line1: "Rua F, 100", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )
  end

  teardown do
    cleanup_tables
  end

  test "Scenario F - Courier accepts, publishes location, picks up, customer tracks, delivers, terminal state reached" do
    # 1. Courier accepts order
    post "/api/v1/courier/orders/#{@order.id}/accept",
      headers: { "Authorization" => "Bearer #{@courier_token}", "Content-Type" => "application/json", "Idempotency-Key" => "scenario-f-accept" }
    assert_response :ok

    # 2. Courier marks pickup
    post "/api/v1/courier/orders/#{@order.id}/pickup",
      headers: { "Authorization" => "Bearer #{@courier_token}", "Content-Type" => "application/json" }
    assert_response :ok
    assert_equal "picked_up", JSON.parse(response.body).dig("data", "order_state")

    # 3. Courier publishes location update
    post "/api/v1/courier/location",
      headers: { "Authorization" => "Bearer #{@courier_token}", "Content-Type" => "application/json" },
      params: { latitude: -23.5505, longitude: -46.6333, accuracy_meters: 5.0 }.to_json
    assert_response :created

    # 4. Customer tracks order and sees state, history and location freshness
    get "/api/v1/customer/orders/#{@order.id}/tracking",
      headers: { "Authorization" => "Bearer #{@customer_token}" }
    assert_response :ok
    tracking = JSON.parse(response.body).fetch("data")
    assert_equal "picked_up", tracking["order_state"]
    assert_equal -23.5505, tracking.dig("location", "latitude")
    assert tracking["freshness_seconds"].present?

    # 5. Courier marks delivered
    post "/api/v1/courier/orders/#{@order.id}/deliver",
      headers: { "Authorization" => "Bearer #{@courier_token}", "Content-Type" => "application/json" }
    assert_response :ok
    assert_equal "delivered", JSON.parse(response.body).dig("data", "order_state")

    # 6. Courier is back to available and order is terminal
    assert_equal "available", @courier.reload.operational_state
    assert_equal "delivered", @order.reload.status

    # 7. Another courier cannot mutate terminal delivery
    other_courier_user = User.create!(email: "other.f.courier@example.com", password: "password123", full_name: "Other F Courier")
    other_courier_user.role_assignments.create!(role: "courier")
    other_courier = Courier.create!(
      user: other_courier_user, phone: "+5511999992222", document_number: "99911122244",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available"
    )
    other_token = Session.issue_for(other_courier_user, ip: "127.0.0.1", user_agent: "Test")

    post "/api/v1/courier/orders/#{@order.id}/deliver",
      headers: { "Authorization" => "Bearer #{other_token}", "Content-Type" => "application/json" }
    assert_response :not_found
  end

  private

  def cleanup_tables
    [ CourierLocation, OutboxEvent, InventoryMovement, Payment, OrderStatusHistory, OrderItem, IdempotencyRecord, Order,
      CartItem, Cart, Address, Favorite, InventoryItem, Product, Category, SellerSettings, SellerMembership,
      Seller, Courier, Customer, RoleAssignment, Session, User ].each(&:delete_all)
  end
end
