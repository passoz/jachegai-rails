require "test_helper"

class Api::V1::Admin::SellersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin@example.com", password: "password123", full_name: "Admin")
    RoleAssignment.create!(user: @admin, role: "admin")
    @admin_token = Session.issue_for(@admin)

    @seller = Seller.create!(name: "Loja Pendente")
    @customer = User.create!(email: "customer@example.com", password: "password123", full_name: "Cliente")
    RoleAssignment.create!(user: @customer, role: "customer")
    @customer_token = Session.issue_for(@customer)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "admin lists sellers with bounded pagination meta" do
    30.times { |index| Seller.create!(name: "Seller #{index}") }

    get "/api/v1/admin/sellers", headers: auth(@admin_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 25, json.dig("data", "sellers").size
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 31, "total_pages" => 2 }, json["meta"])

    get "/api/v1/admin/sellers", params: { page: 1, per_page: 500 }, headers: auth(@admin_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 31, json.dig("data", "sellers").size
    assert_equal 100, json.dig("meta", "per_page")
  end

  test "admin inspects a seller" do
    get "/api/v1/admin/sellers/#{@seller.id}", headers: auth(@admin_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @seller.id, json.dig("data", "id")
  end

  test "admin approves a pending seller and audit is created" do
    post "/api/v1/admin/sellers/#{@seller.id}/approve",
         params: { reason: "documentação ok" }.to_json,
         headers: auth(@admin_token)
    assert_response :ok
    @seller.reload
    assert_equal "approved", @seller.moderation_state
    assert @seller.moderated_at.present?
    audit = AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).last
    assert_equal "approve", audit.action
    assert_equal "success", audit.result
    assert_equal "documentação ok", audit.reason
  end

  test "admin rejects a pending seller" do
    post "/api/v1/admin/sellers/#{@seller.id}/reject",
         params: { reason: "sem documentos" }.to_json,
         headers: auth(@admin_token)
    assert_response :ok
    assert_equal "rejected", @seller.reload.moderation_state
  end

  test "admin suspends an approved seller and reinstate" do
    @seller.update!(moderation_state: "approved")
    post "/api/v1/admin/sellers/#{@seller.id}/suspend",
         params: { reason: "violação" }.to_json,
         headers: auth(@admin_token)
    assert_response :ok
    assert_equal "suspended", @seller.reload.moderation_state

    post "/api/v1/admin/sellers/#{@seller.id}/reinstate",
         headers: auth(@admin_token)
    assert_response :ok
    assert_equal "approved", @seller.reload.moderation_state
  end

  test "transition conflict returns 409" do
    @seller.update!(moderation_state: "approved")
    post "/api/v1/admin/sellers/#{@seller.id}/approve",
         params: { reason: "já aprovado" }.to_json,
         headers: auth(@admin_token)
    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "invalid_transition", json.dig("error", "code")
  end

  test "moderation commands reject malformed JSON and preserve state" do
    post "/api/v1/admin/sellers/#{@seller.id}/approve", params: "not-json", headers: auth(@admin_token)

    assert_response :bad_request
    assert_equal "invalid_json", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending_review", @seller.reload.moderation_state
  end

  test "moderation commands reject non-JSON content and unknown fields" do
    post "/api/v1/admin/sellers/#{@seller.id}/approve",
         params: { reason: "ok" }.to_json,
         headers: auth(@admin_token).merge("Content-Type" => "text/plain")
    assert_response :bad_request
    assert_equal "invalid_content_type", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/admin/sellers/#{@seller.id}/approve",
         params: { unknown: true }.to_json,
         headers: auth(@admin_token)
    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/admin/sellers/#{@seller.id}/approve",
         params: { reason: true }.to_json,
         headers: auth(@admin_token)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
    assert_equal "pending_review", @seller.reload.moderation_state
  end

  test "non-admin is forbidden" do
    get "/api/v1/admin/sellers", headers: auth(@customer_token)
    assert_response :forbidden
  end

  test "admin requests for unknown seller return not found" do
    get "/api/v1/admin/sellers/00000000-0000-0000-0000-000000000000", headers: auth(@admin_token)
    assert_response :not_found
  end

  test "admin endpoints require authentication" do
    get "/api/v1/admin/sellers", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
