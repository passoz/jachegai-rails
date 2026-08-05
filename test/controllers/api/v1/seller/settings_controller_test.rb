require "test_helper"

class Api::V1::Seller::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "settings@example.com", password: "password123", full_name: "Dono")
    RoleAssignment.create!(user: @owner, role: "seller")
    @seller = Seller.create!(name: "Loja de Configurações")
    SellerMembership.create!(seller: @seller, user: @owner, role: "owner")
    @token = Session.issue_for(@owner)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller reads own settings with defaults" do
    get "/api/v1/seller/settings", headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "BRL", json.dig("data", "currency")
    assert_equal false, json.dig("data", "auto_accept_orders")
    assert_equal 30, json.dig("data", "preparation_time_minutes")
  end

  test "seller updates own settings" do
    patch "/api/v1/seller/settings",
          params: { currency: "USD", auto_accept_orders: true, preparation_time_minutes: 45 }.to_json,
          headers: auth(@token)
    assert_response :ok
    settings = @seller.settings
    assert_equal "USD", settings.currency
    assert_equal true, settings.auto_accept_orders
    assert_equal 45, settings.preparation_time_minutes
  end

  test "settings update rejects invalid currency and unknown fields" do
    patch "/api/v1/seller/settings", params: { currency: "reais" }.to_json, headers: auth(@token)
    assert_response :unprocessable_content

    patch "/api/v1/seller/settings", params: { evil: 1 }.to_json, headers: auth(@token)
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "unknown_fields", json.dig("error", "code")
  end

  test "settings requires authentication" do
    get "/api/v1/seller/settings", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
