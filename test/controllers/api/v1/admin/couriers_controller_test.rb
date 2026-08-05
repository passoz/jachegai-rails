require "test_helper"

class Api::V1::Admin::CouriersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(
      email: "admin.couriers@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Admin User"
    )
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user, ip: "127.0.0.1", user_agent: "Test")

    @courier_user = User.create!(
      email: "courier.target@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Target"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511977776666",
      document_number: "99988877766",
      vehicle_type: "motorcycle"
    )
  end

  test "admin lists couriers with bounded deterministic pagination" do
    30.times do |index|
      user = User.create!(
        email: "courier-list-#{index}@example.com",
        password: "password123",
        full_name: "Courier List #{index}"
      )
      user.role_assignments.create!(role: "courier")
      Courier.create!(
        user: user,
        phone: "+5511900#{index.to_s.rjust(7, "0")}",
        document_number: "#{index.to_s.rjust(11, "0")}",
        vehicle_type: "bicycle"
      )
    end

    get "/api/v1/admin/couriers", headers: auth(@admin_token)

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 25, json.dig("data", "couriers").size
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 31, "total_pages" => 2 }, json["meta"])
    expected_ids = Courier.order(created_at: :desc, id: :desc).limit(25).pluck(:id)
    assert_equal expected_ids, json.dig("data", "couriers").pluck("id")

    get "/api/v1/admin/couriers", params: { page: 1, per_page: 500 }, headers: auth(@admin_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 31, json.dig("data", "couriers").size
    assert_equal 100, json.dig("meta", "per_page")
  end

  test "admin inspects courier" do
    get "/api/v1/admin/couriers/#{@courier.id}", headers: auth(@admin_token)

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @courier.id, json.dig("data", "id")
    assert_equal @courier.user_id, json.dig("data", "user_id")
    assert_equal @courier.document_number, json.dig("data", "document_number")
  end

  test "admin approves courier via HTTP POST" do
    post "/api/v1/admin/couriers/#{@courier.id}/approve",
      headers: auth(@admin_token).merge("X-Request-ID" => "courier-moderation-request"),
      params: { reason: "Approved by admin" }.to_json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal "approved", json["data"]["moderation_state"]
    audit = AuditRecord.find_by!(resource_type: "Courier", resource_id: @courier.id, action: "courier.approve")
    assert_equal @admin_user.id, audit.actor_principal_id
    assert_equal "Approved by admin", audit.reason
    assert_equal "courier-moderation-request", audit.correlation_id
    metadata = JSON.parse(audit.metadata)
    assert_equal "pending_review", metadata.fetch("previous_state")
    assert_equal "approved", metadata.fetch("new_state")
  end

  test "moderation rejects malformed JSON without changing state" do
    post "/api/v1/admin/couriers/#{@courier.id}/approve",
      headers: auth(@admin_token),
      params: "not-json"

    assert_response :bad_request
    assert_equal "invalid_json", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending_review", @courier.reload.moderation_state
    assert_empty AuditRecord.where(resource_type: "Courier", resource_id: @courier.id)
  end

  test "moderation rejects unknown fields and non-string reason without changing state" do
    post "/api/v1/admin/couriers/#{@courier.id}/approve",
      headers: auth(@admin_token),
      params: { unknown: true }.to_json
    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/admin/couriers/#{@courier.id}/approve",
      headers: auth(@admin_token),
      params: { reason: true }.to_json
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending_review", @courier.reload.moderation_state
  end

  test "invalid moderation transition returns stable conflict" do
    @courier.update!(moderation_state: "approved")

    post "/api/v1/admin/couriers/#{@courier.id}/approve",
      headers: auth(@admin_token),
      params: { reason: "Already approved" }.to_json

    assert_response :conflict
    assert_equal "invalid_transition", JSON.parse(response.body).dig("error", "code")
    assert_equal "approved", @courier.reload.moderation_state
  end

  test "non-admin cannot list inspect or moderate couriers" do
    courier_token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    get "/api/v1/admin/couriers", headers: auth(courier_token)
    assert_response :forbidden
    get "/api/v1/admin/couriers/#{@courier.id}", headers: auth(courier_token)
    assert_response :forbidden
    post "/api/v1/admin/couriers/#{@courier.id}/approve", headers: auth(courier_token), params: {}.to_json
    assert_response :forbidden
  end

  test "admin courier endpoints require authentication and unknown courier fails closed" do
    get "/api/v1/admin/couriers", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized

    get "/api/v1/admin/couriers/00000000-0000-0000-0000-000000000000", headers: auth(@admin_token)
    assert_response :not_found
  end

  private

  def auth(token)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end
