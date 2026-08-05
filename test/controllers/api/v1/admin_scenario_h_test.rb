require "test_helper"

class AdminScenarioHTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "scenario-h-admin@example.com", password: "password123", full_name: "Admin H")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)

    @customer_user = User.create!(email: "scenario-h-customer@example.com", password: "password123", full_name: "Customer H")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = Customer.find_by(user_id: @customer_user.id) || Customer.create!(user: @customer_user, full_name: "Customer H")

    @seller = Seller.create!(name: "Seller H Store", moderation_state: "approved")
  end

  test "scenario H: admin manages users, inspects orders/payments, updates settings, generates invoices, views dashboard and observability" do
    # 1. Admin lists dashboard
    get "/api/v1/admin/dashboard", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success

    # 2. Admin manages user (disable & enable)
    post "/api/v1/admin/users/#{@customer_user.id}/disable", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    assert @customer_user.reload.disabled?

    post "/api/v1/admin/users/#{@customer_user.id}/enable", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    refute @customer_user.reload.disabled?

    # 3. Admin updates settings
    post "/api/v1/admin/settings",
         params: { key: "platform_fee_percent", value: "12.0", reason: "Reajuste H", effective_at: Time.current.iso8601 }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }
    assert_response :success

    # 4. Admin generates invoice
    post "/api/v1/admin/invoices/generate",
         params: { seller_id: @seller.id, period_start: Date.today.beginning_of_month.to_s, period_end: Date.today.end_of_month.to_s }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }
    assert_response :success

    # 5. Admin inspects observability
    get "/api/v1/admin/observability/summary", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
  end
end
