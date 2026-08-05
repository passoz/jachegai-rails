require "test_helper"
require "support/api_test_controller"

class Api::V1::PolicyAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @customer = User.create!(email: "pol-customer@example.com", password: "password123", full_name: "Policy Customer")
    RoleAssignment.create!(user: @customer, role: "customer")
    @seller = User.create!(email: "pol-seller@example.com", password: "password123", full_name: "Policy Seller")
    RoleAssignment.create!(user: @seller, role: "seller")
    @customer_token = Session.issue_for(@customer)
    @seller_token = Session.issue_for(@seller)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller passes TestApiPolicy#create? and is allowed" do
    post "/api/v1/test/protected", params: { name: "ok" }.to_json, headers: auth(@seller_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json.dig("data", "authorized")
  end

  test "customer without seller role is forbidden" do
    post "/api/v1/test/protected", params: { name: "ok" }.to_json, headers: auth(@customer_token)
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "forbidden", json.dig("error", "code")
  end

  test "unauthenticated request to protected route is unauthorized" do
    post "/api/v1/test/protected", params: { name: "ok" }.to_json, headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
