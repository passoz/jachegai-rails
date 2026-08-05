require "test_helper"

class Api::V1::RateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ratelimit@example.com", password: "password123", full_name: "Rate Limit")
    # Reset limiter between tests
    Api::V1::BaseController.rate_limiter.store.reset
  end

  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  test "login allows multiple attempts under threshold" do
    5.times do
      post "/api/v1/auth/login", params: { email: "ratelimit@example.com", password: "wrong" }.to_json, headers: json_headers
      assert_response :unauthorized
    end
  end

  test "login is rate limited after threshold" do
    5.times { post "/api/v1/auth/login", params: { email: "ratelimit@example.com", password: "wrong" }.to_json, headers: json_headers }
    post "/api/v1/auth/login", params: { email: "ratelimit@example.com", password: "wrong" }.to_json, headers: json_headers
    assert_response :too_many_requests
    assert_equal "5", response.headers["X-RateLimit-Limit"]
    assert_equal "0", response.headers["X-RateLimit-Remaining"]
    assert_equal "60", response.headers["Retry-After"]
    json = JSON.parse(response.body)
    assert_equal "rate_limited", json.dig("error", "code")
  end

  test "rate limit is per IP and identifier" do
    5.times { post "/api/v1/auth/login", params: { email: "ratelimit@example.com", password: "wrong" }.to_json, headers: json_headers }
    post "/api/v1/auth/login",
         params: { email: "other@example.com", password: "wrong" }.to_json,
         headers: json_headers
    assert_response :too_many_requests

    post "/api/v1/auth/login",
         params: { email: "other@example.com", password: "wrong" }.to_json,
         headers: json_headers,
         env: { "REMOTE_ADDR" => "10.0.0.99" }
    assert_response :unauthorized

    post "/api/v1/auth/login",
         params: { email: "ratelimit@example.com", password: "wrong" }.to_json,
         headers: json_headers,
         env: { "REMOTE_ADDR" => "10.0.0.99" }
    assert_response :too_many_requests
  end
end
