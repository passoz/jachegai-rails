require "test_helper"

class Api::V1::Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer

    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "accepted", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @payment = Payment.create!(
      order: @order, state: "pending", amount_cents: 1000, currency: "BRL"
    )

    @admin_user = User.create!(email: "admin@example.com", password: "password123", full_name: "Admin")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)
  end

  test "admin cancels order successfully" do
    post "/api/v1/admin/orders/#{@order.id}/cancel",
         params: { reason: "Admin override" }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.state
  end

  test "admin cannot cancel paid order without refund" do
    @payment.update!(state: "paid")

    post "/api/v1/admin/orders/#{@order.id}/cancel",
         params: { reason: "Force refund" }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :conflict
    assert_equal "refund_required", JSON.parse(response.body).dig("error", "code")
  end

  test "admin lists orders" do
    get "/api/v1/admin/orders", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert json["data"].is_a?(Array)
    assert_equal @order.id, json["data"].first["id"]
  end

  test "admin shows order detail" do
    get "/api/v1/admin/orders/#{@order.id}", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal @order.id, json["data"]["id"]
    assert json["data"]["history"].is_a?(Array)
  end

  test "non-admin cannot cancel order" do
    buyer_token = Session.issue_for(@customer_user)

    post "/api/v1/admin/orders/#{@order.id}/cancel",
         params: { reason: "Force refund" }.to_json,
         headers: { "Authorization" => "Bearer #{buyer_token}", "Content-Type" => "application/json" }

    assert_response :forbidden
  end

  test "invalid payload returns strict error without cancelling the order" do
    post "/api/v1/admin/orders/#{@order.id}/cancel",
         params: { reason: "Admin override", unexpected: true }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
    assert_equal "accepted", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end

  test "cancellation reason must be a string when provided" do
    post "/api/v1/admin/orders/#{@order.id}/cancel",
         params: { reason: 123 }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "accepted", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end
end
