require "test_helper"

class Api::V1::Admin::ObservabilityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "admin-obs@example.com", password: "password123", full_name: "Admin Obs")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)

    @customer_user = User.create!(email: "customer-obs@example.com", password: "password123", full_name: "Customer Obs")
    @customer_token = Session.issue_for(@customer_user)
  end

  test "admin gets observability summary and sub-metrics without PII or secrets" do
    get "/api/v1/admin/observability/summary", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert json["data"].key?("system")
    assert json["data"].key?("outbox")
    assert json["data"]["outbox"].key?("pending_events")
    assert json["data"]["outbox"].key?("failed_events")
    assert json["data"]["outbox"].key?("dead_letter_events")

    get "/api/v1/admin/observability/requests", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success

    get "/api/v1/admin/observability/orders", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success

    get "/api/v1/admin/observability/jobs", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
  end

  test "non-admin is forbidden from accessing observability endpoints" do
    get "/api/v1/admin/observability/summary", headers: { "Authorization" => "Bearer #{@customer_token}" }
    assert_response :forbidden

    get "/api/v1/admin/observability/requests", headers: { "Authorization" => "Bearer #{@customer_token}" }
    assert_response :forbidden
  end
end
