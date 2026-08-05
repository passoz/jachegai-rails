require "test_helper"

class RequestIdMiddlewareTest < ActionDispatch::IntegrationTest
  test "response includes X-Request-ID" do
    get "/healthz"
    assert_response :ok
    assert response.headers["X-Request-ID"].present?
  end

  test "request without ID receives a server-generated ID" do
    get "/healthz"
    request_id = response.headers["X-Request-ID"]
    assert_match(/\A[0-9a-f-]{8,36}\z/, request_id, "Request ID should be a generated identifier")
  end

  test "request with valid ID propagates it" do
    get "/healthz", headers: { "X-Request-ID" => "abc-123" }
    assert_response :ok
    assert_equal "abc-123", response.headers["X-Request-ID"]
  end
end
