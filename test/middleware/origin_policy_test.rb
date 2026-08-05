require "test_helper"
require "support/api_test_controller"

class OriginPolicyTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "origin@example.com", password: "password123", full_name: "Origin User")
    @token = Session.issue_for(@user)
  end

  def auth_headers(extra = {})
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{@token}" }.merge(extra)
  end

  test "mutation without Origin header is allowed (API clients)" do
    post "/api/v1/test/echo", params: { name: "ok" }.to_json, headers: auth_headers
    assert_response :ok
  end

  test "mutation with allowed Origin is allowed" do
    post "/api/v1/test/echo", params: { name: "ok" }.to_json, headers: auth_headers("Origin" => "http://localhost:3000")
    assert_response :ok
  end

  test "mutation with disallowed Origin is rejected" do
    post "/api/v1/test/echo", params: { name: "ok" }.to_json, headers: auth_headers("Origin" => "https://evil.example.com")
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "forbidden", json.dig("error", "code")
  end
end
