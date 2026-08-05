require "test_helper"
require "support/api_test_controller"

class Api::V1::AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "authz@example.com", password: "password123", full_name: "Authz User")
    @token = Session.issue_for(@user)
  end

  test "request without valid token is rejected" do
    get "/api/v1/test/echo", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "request with valid token passes authentication" do
    get "/api/v1/test/echo", headers: {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{@token}"
    }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
  end

  test "request with revoked token is rejected" do
    SessionService.logout(@token)
    get "/api/v1/test/echo", headers: {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{@token}"
    }
    assert_response :unauthorized
  end
end
