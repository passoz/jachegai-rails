require "test_helper"

class Api::V1::Admin::PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer = Customer.create!(user: @customer_user, full_name: "Buyer")
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

    @admin_user = User.create!(email: "admin@example.com", password: "password123", full_name: "Admin")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)
  end

  test "admin confirms payment successfully" do
    post "/api/v1/admin/payments/#{@payment.id}/confirm",
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "paid", @payment.reload.state
    json = JSON.parse(response.body)
    assert_equal "paid", json.dig("data", "state")
  end

  test "confirming already paid payment is successful" do
    @payment.update!(state: "paid")

    post "/api/v1/admin/payments/#{@payment.id}/confirm",
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success
  end

  test "confirming with invalid state returns conflict" do
    @payment.update!(state: "failed")

    post "/api/v1/admin/payments/#{@payment.id}/confirm",
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :conflict
    assert_equal "payment_conflict", JSON.parse(response.body).dig("error", "code")
  end

  test "admin lists payments" do
    get "/api/v1/admin/payments", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert json["data"].is_a?(Array)
    assert_equal @payment.id, json["data"].first["id"]
  end

  test "admin shows payment detail" do
    get "/api/v1/admin/payments/#{@payment.id}", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal @payment.id, json["data"]["id"]
  end

  test "non-admin receives forbidden or unauthorized" do
    customer_token = Session.issue_for(@customer_user)

    post "/api/v1/admin/payments/#{@payment.id}/confirm",
         headers: { "Authorization" => "Bearer #{customer_token}", "Content-Type" => "application/json" }

    assert_response :forbidden
  end
end
