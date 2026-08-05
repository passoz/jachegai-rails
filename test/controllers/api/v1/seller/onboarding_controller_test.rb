require "test_helper"

class Api::V1::Seller::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller_user = User.create!(email: "onboarding@example.com", password: "password123", full_name: "Vendedor")
    RoleAssignment.create!(user: @seller_user, role: "seller")
    @token = Session.issue_for(@seller_user)

    @customer = User.create!(email: "onboarding-client@example.com", password: "password123", full_name: "Cliente")
    RoleAssignment.create!(user: @customer, role: "customer")
    @customer_token = Session.issue_for(@customer)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller role completes onboarding with 201 and pending_review state" do
    post "/api/v1/seller/onboarding",
         params: { name: "Empório do Centro", contact_email: "contato@emporio.com" }.to_json,
         headers: auth(@token)

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert_equal "pending_review", json.dig("data", "moderation_state")
    assert_equal "Empório do Centro", json.dig("data", "name")
    assert json.dig("data", "id").present?
  end

  test "onboarding is rejected for a user without seller role" do
    post "/api/v1/seller/onboarding",
         params: { name: "Loja Fantasma" }.to_json,
         headers: auth(@customer_token)

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "forbidden", json.dig("error", "code")
  end

  test "onboarding is rejected when the seller user already owns a seller" do
    post "/api/v1/seller/onboarding", params: { name: "Primeira" }.to_json, headers: auth(@token)
    assert_response :created

    post "/api/v1/seller/onboarding", params: { name: "Segunda" }.to_json, headers: auth(@token)
    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "already_exists", json.dig("error", "code")
  end

  test "onboarding rejects unknown fields" do
    post "/api/v1/seller/onboarding",
         params: { name: "Loja", evil: "x" }.to_json,
         headers: auth(@token)

    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "unknown_fields", json.dig("error", "code")
  end

  test "onboarding returns validation errors instead of internal errors" do
    post "/api/v1/seller/onboarding", params: {}.to_json, headers: auth(@token)
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
    assert json.dig("error", "context", "fields", "name").present?

    post "/api/v1/seller/onboarding",
         params: { name: "Loja", contact_email: "invalid" }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/seller/onboarding", params: { name: true }.to_json, headers: auth(@token)
    assert_response :unprocessable_content
  end

  test "onboarding requires authentication" do
    post "/api/v1/seller/onboarding",
         params: { name: "Loja" }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
