require "test_helper"

class Api::V1::Courier::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier = create_courier(index: 1, operational_state: "available")
    @other_courier = create_courier(index: 2, operational_state: "on_delivery")
    @token = Session.issue_for(@courier.user, ip: "127.0.0.1", user_agent: "Test")
    @seller = Seller.create!(name: "Queue Store", moderation_state: "approved")
    customer_user = User.create!(email: "customer.queue@example.com", password: "password123", full_name: "Customer Queue")
    customer_user.role_assignments.create!(role: "customer")
    @customer = customer_user.customer
    @ready_order = create_order(status: "ready")
  end

  test "approved available courier sees only paginated ready unassigned orders in deterministic order" do
    29.times { create_order(status: "ready") }
    tied_time = Time.zone.parse("2026-08-03 12:00:00")
    Order.where(status: "ready", courier_id: nil).update_all(created_at: tied_time, updated_at: tied_time)
    create_order(status: "ready", courier: @other_courier)
    create_order(status: "assigned", courier: @other_courier)
    create_order(status: "delivered", courier: @other_courier)

    get "/api/v1/courier/orders/eligible", headers: auth

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 25, json["data"].size
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 30, "total_pages" => 2 }, json["meta"])
    expected_ids = Order.where(status: "ready", courier_id: nil).order(created_at: :asc, id: :asc).limit(25).pluck(:id)
    assert_equal expected_ids, json["data"].pluck("id")
    json["data"].each do |order|
      assert_equal %w[courier_fee_cents created_at currency id order_state seller_id], order.keys.sort
      refute order.key?("customer_id")
      refute order.key?("delivery_address")
      refute order.key?("items")
      refute order.key?("payment_state")
    end
  end

  test "eligible collection preloads serialized associations without per-order queries" do
    5.times { create_order(status: "ready") }
    sql = []
    subscriber = lambda do |*, payload|
      next if payload[:name].in?([ "SCHEMA", "CACHE" ])
      next if payload[:cached]

      sql << payload[:sql]
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get "/api/v1/courier/orders/eligible", headers: auth
    end

    assert_response :ok
    item_queries = sql.count { |statement| statement.include?('FROM "order_items"') }
    payment_queries = sql.count { |statement| statement.include?('FROM "payments"') }
    assert_operator item_queries, :<=, 1
    assert_operator payment_queries, :<=, 1
  end

  test "offline or unapproved courier cannot view eligible queue" do
    @courier.update!(operational_state: "offline")

    get "/api/v1/courier/orders/eligible", headers: auth

    assert_response :unprocessable_content
    assert_equal "courier_not_available", JSON.parse(response.body).dig("error", "code")
  end

  test "active returns only the current courier assignment" do
    @courier.update!(operational_state: "on_delivery")
    own_active = create_order(status: "assigned", courier: @courier)
    create_order(status: "picked_up", courier: @other_courier)

    get "/api/v1/courier/orders/active", headers: auth

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal own_active.id, json.dig("data", "id")
  end

  test "active returns null when current courier has no assignment" do
    create_order(status: "assigned", courier: @other_courier)

    get "/api/v1/courier/orders/active", headers: auth

    assert_response :ok
    assert_nil JSON.parse(response.body)["data"]
  end

  test "history returns only own delivered orders with bounded deterministic pagination" do
    @courier.update!(operational_state: "offline")
    30.times { create_order(status: "delivered", courier: @courier) }
    tied_time = Time.zone.parse("2026-08-03 12:00:00")
    Order.where(status: "delivered", courier_id: @courier.id).update_all(created_at: tied_time, updated_at: tied_time)
    create_order(status: "delivered", courier: @other_courier)

    get "/api/v1/courier/orders/history", headers: auth

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 25, json["data"].size
    assert_equal 30, json.dig("meta", "total")
    expected_ids = Order.where(courier_id: @courier.id, status: "delivered").order(updated_at: :desc, id: :desc).limit(25).pluck(:id)
    assert_equal expected_ids, json["data"].pluck("id")
    refute_includes json["data"].pluck("id"), Order.where(courier_id: @other_courier.id, status: "delivered").pick(:id)
  end

  private

  def auth
    { "Authorization" => "Bearer #{@token}" }
  end

  def create_courier(index:, operational_state:)
    user = User.create!(email: "courier-queue-#{index}@example.com", password: "password123", full_name: "Courier Queue #{index}")
    user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: user,
      phone: "+55119444433#{index.to_s.rjust(2, "0")}",
      document_number: (333_444_555_60 + index).to_s,
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: operational_state
    )
  end

  def create_order(status:, courier: nil)
    Order.create!(
      customer: @customer,
      seller: @seller,
      courier: courier,
      status: status,
      subtotal_cents: 2_000,
      delivery_fee_cents: 500,
      total_cents: 2_500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua A, 123",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end
end
