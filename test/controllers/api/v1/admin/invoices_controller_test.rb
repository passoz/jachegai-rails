require "test_helper"

class Api::V1::Admin::InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "admin-invoices@example.com", password: "password123", full_name: "Admin Invoices")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user)

    @seller = Seller.create!(name: "Seller Invoice Controller Test", moderation_state: "approved")
  end

  test "admin generates, lists and shows invoices" do
    post "/api/v1/admin/invoices/generate",
         params: { seller_id: @seller.id, period_start: Date.today.beginning_of_month.to_s, period_end: Date.today.end_of_month.to_s }.to_json,
         headers: { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    invoice_id = json["data"]["id"]

    get "/api/v1/admin/invoices", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal invoice_id, json["data"].first["id"]

    get "/api/v1/admin/invoices/#{invoice_id}", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal invoice_id, json["data"]["id"]
  end
end
