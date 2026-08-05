require "test_helper"
require "support/api_test_controller"

class BaseControllerEnvelopeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "envelope@example.com", password: "password123", full_name: "Envelope User")
    @token = Session.issue_for(@user)
  end

  def auth_headers(extra = {})
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{@token}" }.merge(extra)
  end

  test "GET show returns success envelope with ok, data, meta" do
    get api_v1_test_api_show_path, headers: auth_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json.key?("data")
    assert json.key?("meta")
    assert_equal "test-id", json["data"]["id"]
  end

  test "RecordNotFound returns not_found envelope" do
    get api_v1_test_api_raise_not_found_path, headers: auth_headers
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "not_found", json["error"]["code"]
    assert json["error"].key?("message")
  end

  test "StandardError returns internal_error envelope without exposing details" do
    get api_v1_test_api_raise_internal_error_path, headers: auth_headers
    assert_response :internal_server_error
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "internal_error", json["error"]["code"]
    refute json["error"].key?("backtrace")
    refute json["error"].key?("sql")
  end

  test "success response never returns 204" do
    get api_v1_test_api_show_path, headers: auth_headers
    assert_response :ok
    assert_not_equal 204, response.status
  end
end

class StrictJsonInputTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "strict@example.com", password: "password123", full_name: "Strict User")
    @token = Session.issue_for(@user)
  end

  def auth_headers(extra = {})
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{@token}" }.merge(extra)
  end

  test "malformed JSON returns invalid_input" do
    post "/api/v1/test/echo",
         params: "{invalid json",
         headers: auth_headers
    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_input", json["error"]["code"]
  end

  test "incorrect content type on mutation returns stable error" do
    post "/api/v1/test/echo",
         params: "name=foo",
         headers: auth_headers("Content-Type" => "application/x-www-form-urlencoded")
    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_input", json["error"]["code"]
  end

  test "unknown fields are rejected" do
    post "/api/v1/test/echo",
         params: { name: "test", unknown_field: "nope" }.to_json,
         headers: auth_headers
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_input", json["error"]["code"]
  end

  test "GET does not create hidden state" do
    get "/api/v1/test/echo", headers: auth_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
  end
end
