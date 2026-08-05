require "test_helper"

class Api::V1::Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "admin-settings@example.com", password: "password123", full_name: "Admin Settings")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)

    @customer_user = User.create!(email: "customer-settings@example.com", password: "password123", full_name: "Customer Settings")
    @customer_token = Session.issue_for(@customer_user)
  end

  test "admin can list and update marketplace settings with reason" do
    post "/api/v1/admin/settings",
         params: { key: "platform_fee_percent", value: "10.0", reason: "Reajuste anual", effective_at: Time.current.iso8601 }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "platform_fee_percent", json["data"]["key"]
    assert_equal "10.0", json["data"]["value"]

    get "/api/v1/admin/settings", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    setting_keys = json["data"].map { |s| s["key"] }
    assert_includes setting_keys, "platform_fee_percent"
  end

  test "setting change does not mutate existing order fee snapshot" do
    seller = Seller.create!(name: "Store Settings Test", moderation_state: "approved")
    customer = Customer.create!(user: @customer_user, full_name: "Customer Settings")
    order = Order.create!(
      customer: customer, seller: seller, status: "pending", currency: "BRL",
      subtotal_cents: 2000, delivery_fee_cents: 500, discount_cents: 0, courier_fee_cents: 400,
      total_cents: 2500, address_name: "Home", address_line1: "Line 1", address_city: "City", address_state: "ST", address_zip: "123", address_country: "BR"
    )

    post "/api/v1/admin/settings",
         params: { key: "delivery_fee_cents", value: "800", reason: "Aumento de frete", effective_at: Time.current.iso8601 }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success

    order.reload
    assert_equal 500, order.delivery_fee_cents, "order snapshot must remain unchanged"
  end

  test "non-admin receives 403 forbidden" do
    get "/api/v1/admin/settings", headers: { "Authorization" => "Bearer #{@customer_token}" }
    assert_response :forbidden

    post "/api/v1/admin/settings",
         params: { key: "fee", value: "5", reason: "test" }.to_json,
         headers: { "Authorization" => "Bearer #{@customer_token}", "Content-Type" => "application/json" }
    assert_response :forbidden
  end
end
