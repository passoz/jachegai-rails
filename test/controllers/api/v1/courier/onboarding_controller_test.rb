require "test_helper"

class Api::V1::Courier::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(
      email: "courier.onboarding@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Onboarding User"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier_token = generate_token_for(@courier_user)

    @customer_user = User.create!(
      email: "customer.user@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Customer User"
    )
    @customer_user.role_assignments.create!(role: "customer")
    @customer_token = generate_token_for(@customer_user)
  end

  test "courier user performs onboarding successfully" do
    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@courier_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988887777",
        document_number: "11122233344",
        vehicle_type: "motorcycle",
        vehicle_plate: "XYZ9876",
        location_consent: true
      }.to_json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "pending_review", json["data"]["moderation_state"]
    assert_equal "offline", json["data"]["operational_state"]
    assert_equal "+5511988887777", json["data"]["phone"]
    assert_equal "11122233344", json["data"]["document_number"]
    assert_equal "motorcycle", json["data"]["vehicle_type"]
    assert json["data"]["location_consent_given_at"].present?
    assert_equal "7", json.dig("data", "id")[14]
  end

  test "cannot perform onboarding twice for the same user" do
    Courier.create!(
      user: @courier_user,
      phone: "+5511988887777",
      document_number: "11122233344",
      vehicle_type: "motorcycle"
    )

    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@courier_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988887777",
        document_number: "11122233344",
        vehicle_type: "motorcycle"
      }.to_json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    refute json["ok"]
    assert_equal "courier_already_exists", json["error"]["code"]
  end

  test "user without courier role cannot perform courier onboarding" do
    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@customer_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988887777",
        document_number: "11122233344",
        vehicle_type: "motorcycle"
      }.to_json

    assert_response :forbidden
  end

  test "rejects non-string profile fields without creating courier" do
    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@courier_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: 55_119_888_877,
        document_number: 11_122_233_344,
        vehicle_type: true,
        vehicle_plate: 123
      }.to_json

    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
    assert_nil @courier_user.reload.courier
  end

  test "rejects non-boolean location consent without creating courier" do
    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@courier_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988887777",
        document_number: "11122233344",
        vehicle_type: "motorcycle",
        location_consent: "false"
      }.to_json

    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
    assert_nil @courier_user.reload.courier
  end

  test "rejects onboarding with malformed or unknown fields" do
    post "/api/v1/courier/onboarding",
      headers: { "Authorization" => "Bearer #{@courier_token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988887777",
        document_number: "11122233344",
        vehicle_type: "motorcycle",
        hacker_field: "injected"
      }.to_json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "unknown_fields", json["error"]["code"]
  end

  private

  def generate_token_for(user)
    Session.issue_for(user, ip: "127.0.0.1", user_agent: "Test")
  end
end
