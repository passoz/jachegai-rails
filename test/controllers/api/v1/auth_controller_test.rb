require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  def json_headers(extra = {})
    { "Content-Type" => "application/json", "Accept" => "application/json" }.merge(extra)
  end

  test "register rejects a valid JSON body with the wrong content type" do
    post "/api/v1/auth/register",
         params: { email: "wrong-type@example.com", password: "password123", full_name: "Wrong Type" }.to_json,
         headers: json_headers("Content-Type" => "text/plain")
    assert_response :bad_request
    assert_equal "invalid_content_type", JSON.parse(response.body).dig("error", "code")
  end

  test "register rejects an oversized body before persistence" do
    payload = { email: "large@example.com", password: "password123", full_name: "x" * (StrictJson::DEFAULT_MAX_BYTES + 1) }.to_json
    assert_no_difference -> { User.count } do
      post "/api/v1/auth/register", params: payload, headers: json_headers
    end
    assert_response :content_too_large
    assert_equal "payload_too_large", JSON.parse(response.body).dig("error", "code")
  end

  test "register creates user, customer profile, customer role, and returns token" do
    assert_difference -> { User.count } => 1, -> { Customer.count } => 1 do
      post "/api/v1/auth/register",
           params: { email: "new@example.com", password: "password123", full_name: "New User" }.to_json,
           headers: json_headers
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json.dig("data", "token").present?
    user = User.find_by(email: "new@example.com")
    assert user.present?
    assert_equal :customer, user.roles.first
    assert_equal "New User", user.customer.full_name
    refute_equal user.id, user.customer.id
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}\z/, user.id)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}\z/, user.customer.id)
  end

  test "register rejects duplicate email" do
    User.create!(email: "dup@example.com", password: "password123", full_name: "Dup")
    post "/api/v1/auth/register",
         params: { email: "dup@example.com", password: "password123", full_name: "Dup2" }.to_json,
         headers: json_headers
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_input", json.dig("error", "code")
  end

  test "register rejects weak password" do
    post "/api/v1/auth/register",
         params: { email: "weak@example.com", password: "short", full_name: "Weak" }.to_json,
         headers: json_headers
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "invalid_input", json.dig("error", "code")
  end

  test "login returns token and user" do
    user = User.create!(email: "login@example.com", password: "password123", full_name: "Login User")
    RoleAssignment.create!(user: user, role: "customer")
    post "/api/v1/auth/login",
         params: { email: "login@example.com", password: "password123" }.to_json,
         headers: json_headers
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json.dig("data", "token").present?
    assert_equal user.id, json.dig("data", "user", "id")
    assert_includes json.dig("data", "user", "roles"), "customer"
  end

  test "login rejects wrong credentials" do
    User.create!(email: "login2@example.com", password: "password123", full_name: "Login2")
    post "/api/v1/auth/login",
         params: { email: "login2@example.com", password: "wrongpassword" }.to_json,
         headers: json_headers
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal false, json["ok"]
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "login rejects unknown email (no enumeration)" do
    post "/api/v1/auth/login",
         params: { email: "ghost@example.com", password: "password123" }.to_json,
         headers: json_headers
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "me returns current principal" do
    user = User.create!(email: "me@example.com", password: "password123", full_name: "Me User")
    RoleAssignment.create!(user: user, role: "customer")
    token = Session.issue_for(user)
    get "/api/v1/auth/me", headers: json_headers("Authorization" => "Bearer #{token}")
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert_equal user.id, json.dig("data", "id")
    assert_equal "me@example.com", json.dig("data", "email")
  end

  test "me without token is unauthorized" do
    get "/api/v1/auth/me", headers: json_headers
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "unauthorized", json.dig("error", "code")
  end

  test "logout revokes token" do
    user = User.create!(email: "logout@example.com", password: "password123", full_name: "Logout User")
    token = Session.issue_for(user)
    post "/api/v1/auth/logout", headers: json_headers("Authorization" => "Bearer #{token}")
    assert_response :ok
    assert_nil Session.find_by_token(token)
  end
end
