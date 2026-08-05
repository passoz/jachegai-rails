require "test_helper"

class Api::V1::Seller::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer = Customer.create!(user: @customer_user, full_name: "Buyer")

    @seller_user = User.create!(email: "merchant@example.com", password: "password123", full_name: "Merchant")
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")
    @seller_token = Session.issue_for(@seller_user)

    @other_user = User.create!(email: "other@example.com", password: "password123", full_name: "Other")
    @other_user.role_assignments.create!(role: "seller")
    @other_seller = Seller.create!(name: "Other Store", moderation_state: "approved")
    @other_user.seller_memberships.create!(seller: @other_seller, role: "owner")
    @other_token = Session.issue_for(@other_user)

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @payment = Payment.create!(
      order: @order, state: "pending", amount_cents: 1000, currency: "BRL"
    )
  end

  test "unauthenticated request is rejected" do
    get "/api/v1/seller/orders"

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body).dig("error", "code")
  end

  test "seller lists only own orders with pagination" do
    get "/api/v1/seller/orders",
        headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].size
    assert_equal @order.id, json["data"][0]["id"]
  end

  test "other seller receives empty list" do
    get "/api/v1/seller/orders",
        headers: { "Authorization" => "Bearer #{@other_token}" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 0, json["data"].size
  end

  test "seller membership without seller role is forbidden" do
    @seller_user.role_assignments.where(role: "seller").delete_all

    get "/api/v1/seller/orders",
        headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :forbidden
  end

  test "seller can show own order with history and items" do
    get "/api/v1/seller/orders/#{@order.id}",
        headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @order.id, json.dig("data", "id")
    assert_not_nil json.dig("data", "history")
    assert_not_nil json.dig("data", "items")
  end

  test "seller cannot show other seller order" do
    get "/api/v1/seller/orders/#{@order.id}",
        headers: { "Authorization" => "Bearer #{@other_token}" }

    assert_response :not_found
  end

  test "seller can accept order after it is paid" do
    @payment.update!(state: "paid")

    post "/api/v1/seller/orders/#{@order.id}/accept",
         headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :success
    assert_equal "accepted", @order.reload.status
  end

  test "seller cannot accept order if not paid" do
    post "/api/v1/seller/orders/#{@order.id}/accept",
         headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "payment_required", json.dig("error", "code")
  end

  test "other seller cannot accept order" do
    @payment.update!(state: "paid")

    post "/api/v1/seller/orders/#{@order.id}/accept",
         headers: { "Authorization" => "Bearer #{@other_token}" }

    assert_response :not_found
    assert_equal "pending", @order.reload.status
  end

  test "seller can progress status preparing and ready" do
    @payment.update!(state: "paid")
    @order.update!(status: "accepted")

    post "/api/v1/seller/orders/#{@order.id}/preparing",
         headers: { "Authorization" => "Bearer #{@seller_token}" }
    assert_response :success
    assert_equal "preparing", @order.reload.status

    post "/api/v1/seller/orders/#{@order.id}/ready",
         headers: { "Authorization" => "Bearer #{@seller_token}" }
    assert_response :success
    assert_equal "ready", @order.reload.status
  end

  test "scenario D prepares an order with actor and timestamp evidence" do
    admin = User.create!(email: "orders-admin@example.com", password: "password123", full_name: "Admin")
    admin.role_assignments.create!(role: "admin")
    admin_token = Session.issue_for(admin)

    post "/api/v1/admin/payments/#{@payment.id}/confirm",
         headers: { "Authorization" => "Bearer #{admin_token}" }
    assert_response :success

    %w[accept preparing ready].each do |action|
      post "/api/v1/seller/orders/#{@order.id}/#{action}",
           headers: { "Authorization" => "Bearer #{@seller_token}" }
      assert_response :success
    end

    assert_equal "ready", @order.reload.status
    histories = @order.order_status_histories.order(:occurred_at, :id).to_a
    assert_equal %w[accepted preparing ready], histories.last(3).map(&:to_status)
    assert histories.last(3).all? { |history| history.actor_principal_id == "user:#{@seller_user.id}" }
    assert histories.last(3).all? { |history| history.occurred_at.present? }

    get "/api/v1/seller/orders/#{@order.id}",
        headers: { "Authorization" => "Bearer #{@other_token}" }
    assert_response :not_found

    post "/api/v1/seller/orders/#{@order.id}/ready",
         headers: { "Authorization" => "Bearer #{@other_token}" }
    assert_response :not_found
  end

  test "invalid transitions return unprocessable entity" do
    @payment.update!(state: "paid")

    # Try preparing directly from pending (invalid step jump)
    post "/api/v1/seller/orders/#{@order.id}/preparing",
         headers: { "Authorization" => "Bearer #{@seller_token}" }

    assert_response :unprocessable_content
    assert_equal "invalid_transition", JSON.parse(response.body).dig("error", "code")
  end

  test "reject uses strict payload parsing without mutating on unknown fields" do
    post "/api/v1/seller/orders/#{@order.id}/reject",
         params: { reason: "Unavailable", unexpected: true }.to_json,
         headers: { "Authorization" => "Bearer #{@seller_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end

  test "reject reason must be a string when provided" do
    post "/api/v1/seller/orders/#{@order.id}/reject",
         params: { reason: 123 }.to_json,
         headers: { "Authorization" => "Bearer #{@seller_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end
end
