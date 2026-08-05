require "test_helper"

class Api::V1::Courier::AssignmentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(
      email: "courier.http.assign@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier HTTP Assign"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511933330000",
      document_number: "33300033300",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "available"
    )
    @token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    @seller_user = User.create!(
      email: "seller.http.assign@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Seller HTTP Assign"
    )
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "HTTP Assign Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")

    @customer_user = User.create!(
      email: "customer.http.assign@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Customer HTTP Assign"
    )
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer || Customer.create!(user: @customer_user, full_name: @customer_user.full_name)

    @order = Order.create!(
      customer: @customer,
      seller: @seller,
      status: "ready",
      subtotal_cents: 2000,
      delivery_fee_cents: 500,
      total_cents: 2500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua C, 789",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end

  test "courier endpoints require authentication and courier role" do
    post "/api/v1/courier/orders/#{@order.id}/accept", headers: { "Idempotency-Key" => "no-auth" }
    assert_response :unauthorized

    customer_user = User.create!(email: "assignment-role-customer@example.com", password: "password123", full_name: "Customer")
    customer_user.role_assignments.create!(role: "customer")
    post "/api/v1/courier/orders/#{@order.id}/accept",
      headers: {
        "Authorization" => "Bearer #{Session.issue_for(customer_user)}",
        "Idempotency-Key" => "wrong-role"
      }
    assert_response :forbidden
    assert_equal "ready", @order.reload.status
  end

  test "unknown order fails closed without assignment evidence" do
    post "/api/v1/courier/orders/#{ApplicationId.generate}/accept",
      headers: {
        "Authorization" => "Bearer #{@token}",
        "Idempotency-Key" => "unknown-order"
      }

    assert_response :not_found
    assert_equal "not_found", JSON.parse(response.body).dig("error", "code")
    assert_empty OrderStatusHistory.all
    assert_empty OutboxEvent.all
  end

  test "unexpected assignment failure is sanitized" do
    failing_service = Object.new
    failing_service.define_singleton_method(:accept_order!) { |*, **| raise "sensitive assignment detail" }

    with_assignment_service(failing_service) { post_accept(order: @order, key: "internal-failure") }

    assert_response :internal_server_error
    assert_equal "internal_error", JSON.parse(response.body).dig("error", "code")
    refute_includes response.body, "sensitive assignment detail"
    assert_equal "ready", @order.reload.status
  end

  test "courier accepts order with mandatory idempotency key" do
    post_accept(order: @order, key: "assignment-key")

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "assigned", json["data"]["order_state"]
    record = IdempotencyRecord.find_by!(principal_id: @courier_user.id, operation: "courier_assignment", key: "assignment-key")
    assert_equal "completed", record.state
    assert_equal @order.id, record.resource_id
  end

  test "missing or oversized idempotency key is rejected without mutation" do
    post_accept(order: @order, key: nil)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")

    post_accept(order: @order, key: "x" * 129)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "ready", @order.reload.status
    assert_nil @order.courier_id
  end

  test "same key and order replays original assignment without duplicate evidence" do
    post_accept(order: @order, key: "assignment-retry")
    assert_response :ok
    first_id = JSON.parse(response.body).dig("data", "id")
    counts = [ OrderStatusHistory.count, OutboxEvent.count, IdempotencyRecord.count ]

    post_accept(order: @order, key: "assignment-retry")

    assert_response :ok
    assert_equal first_id, JSON.parse(response.body).dig("data", "id")
    assert_equal counts, [ OrderStatusHistory.count, OutboxEvent.count, IdempotencyRecord.count ]
  end

  test "same key for a different order returns idempotency conflict" do
    other_order = @order.dup
    other_order.id = nil
    other_order.save!
    post_accept(order: @order, key: "assignment-conflict")
    assert_response :ok

    post_accept(order: other_order, key: "assignment-conflict")

    assert_response :conflict
    assert_equal "idempotency_conflict", JSON.parse(response.body).dig("error", "code")
    assert_equal "ready", other_order.reload.status
    assert_nil other_order.courier_id
  end

  private

  def with_assignment_service(service)
    original_constructor = CourierAssignmentService.method(:new)
    CourierAssignmentService.define_singleton_method(:new) { service }
    yield
  ensure
    CourierAssignmentService.define_singleton_method(:new, original_constructor)
  end

  def post_accept(order:, key:)
    headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
    headers["Idempotency-Key"] = key if key
    post "/api/v1/courier/orders/#{order.id}/accept", headers: headers
  end
end
