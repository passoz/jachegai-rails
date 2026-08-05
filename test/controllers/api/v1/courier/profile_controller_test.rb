require "test_helper"

class Api::V1::Courier::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "courier.profile@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Profile User"
    )
    @user.role_assignments.create!(role: "courier")
    @token = generate_token_for(@user)

    @courier = Courier.create!(
      user: @user,
      phone: "+5511999991111",
      document_number: "55566677788",
      vehicle_type: "motorcycle",
      vehicle_plate: "OLD1234"
    )
  end

  test "gets courier profile successfully" do
    get "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal @courier.id, json["data"]["id"]
    assert_equal "+5511999991111", json["data"]["phone"]
    assert_equal "pending_review", json["data"]["moderation_state"]
  end

  test "updates courier profile successfully" do
    patch "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: {
        phone: "+5511988882222",
        vehicle_type: "bicycle",
        vehicle_plate: nil
      }.to_json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "+5511988882222", json["data"]["phone"]
    assert_equal "bicycle", json["data"]["vehicle_type"]
    assert_nil json["data"]["vehicle_plate"]
  end

  test "rejects non-string profile values without mutation" do
    original = @courier.attributes.slice("phone", "vehicle_type", "vehicle_plate", "location_consent_given_at")

    patch "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { phone: 123, vehicle_type: true, vehicle_plate: 456 }.to_json

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal original, @courier.reload.attributes.slice(*original.keys)
  end

  test "rejects non-boolean location consent without mutation" do
    patch "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { location_consent: "false" }.to_json

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_nil @courier.reload.location_consent_given_at
  end

  test "cannot update restricted fields via profile update" do
    patch "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: {
        moderation_state: "approved"
      }.to_json

    assert_response :unprocessable_entity
  end

  test "returns 404 for courier user without onboarding" do
    user_no_courier = User.create!(
      email: "courier.no.onboarding@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "No Onboarding"
    )
    user_no_courier.role_assignments.create!(role: "courier")
    token_no_onboarding = generate_token_for(user_no_courier)

    get "/api/v1/courier/profile",
      headers: { "Authorization" => "Bearer #{token_no_onboarding}" }

    assert_response :not_found
  end

  private

  def generate_token_for(user)
    Session.issue_for(user, ip: "127.0.0.1", user_agent: "Test")
  end
end
