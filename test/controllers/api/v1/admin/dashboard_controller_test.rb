require "test_helper"

class Api::V1::Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "admin-dashboard@example.com", password: "password123", full_name: "Admin Dashboard")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)

    @customer_user = User.create!(email: "customer-dashboard@example.com", password: "password123", full_name: "Customer Dashboard")
    @customer_token = Session.issue_for(@customer_user)
  end

  test "admin gets operational dashboard metrics" do
    get "/api/v1/admin/dashboard", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    data = json["data"]

    assert data.key?("users")
    assert data.key?("sellers")
    assert data.key?("couriers")
    assert data.key?("orders")
    assert data.key?("tickets")
    assert data.key?("payments")
  end

  test "non-admin receives 403 forbidden for dashboard" do
    get "/api/v1/admin/dashboard", headers: { "Authorization" => "Bearer #{@customer_token}" }
    assert_response :forbidden
  end
end
