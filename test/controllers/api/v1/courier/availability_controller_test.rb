require "test_helper"

class Api::V1::Courier::AvailabilityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(
      email: "courier.avail.http@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Avail HTTP"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511955554444",
      document_number: "44455566677",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "offline"
    )
    @token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")
  end

  test "courier updates operational state to available" do
    patch "/api/v1/courier/availability",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { state: "available" }.to_json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "available", json["data"]["operational_state"]
  end

  test "rejects non-string availability without state mutation" do
    patch "/api/v1/courier/availability",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { state: 1 }.to_json

    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "offline", @courier.reload.operational_state
  end

  test "returns error when attempting invalid operational state" do
    patch "/api/v1/courier/availability",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { state: "invalid_state" }.to_json

    assert_response :unprocessable_entity
  end
end
