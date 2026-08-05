require "test_helper"

class Api::V1::Customer::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer
    @customer_token = Session.issue_for(@customer_user)

    @other_user = User.create!(email: "other@example.com", password: "password123", full_name: "Other")
    @other_user.role_assignments.create!(role: "customer")
    @other_customer = @other_user.customer
    @other_token = Session.issue_for(@other_user)

    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")

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

  test "customer cancels own pending order with reason" do
    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: "Changed my mind" }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "cancelled", @order.reload.status
    assert_equal "failed", @payment.reload.state
  end

  test "cancelling without reason returns unprocessable content" do
    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: {}.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "reason_required", JSON.parse(response.body).dig("error", "code")
  end

  test "cancellation reason must be a string" do
    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: 123 }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end

  test "customer cannot cancel other customer order" do
    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: "Hack attempt" }.to_json,
         headers: { "Authorization" => "Bearer #{@other_token}", "Content-Type" => "application/json" }

    assert_response :not_found
    assert_equal "pending", @order.reload.status
  end

  test "authenticated principal without customer role is forbidden" do
    @customer_user.role_assignments.where(role: "customer").delete_all
    @customer_user.role_assignments.create!(role: "seller")

    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: "Role bypass" }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :forbidden
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end

  test "customer cannot cancel accepted order" do
    @order.update!(status: "accepted")

    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: "Changed mind" }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "invalid_transition", JSON.parse(response.body).dig("error", "code")
  end

  test "invalid payload returns strict error without cancelling the order" do
    post "/api/v1/customer/orders/#{@order.id}/cancel",
         params: { reason: "Changed my mind", unexpected: true }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending", @order.reload.status
    assert_equal "pending", @payment.reload.state
  end
end
