require "test_helper"

class Api::V1::SupportScenarioGTest < ActionDispatch::IntegrationTest
  test "Scenario G - customer opens support ticket and admin resolves it" do
    customer_user = User.create!(email: "scenario.g.customer@example.com", password: "password123", full_name: "Scenario G Customer")
    customer_user.role_assignments.create!(role: "customer")
    customer_token = Session.issue_for(customer_user, ip: "127.0.0.1", user_agent: "Test")

    admin_user = User.create!(email: "scenario.g.admin@example.com", password: "password123", full_name: "Scenario G Admin")
    admin_user.role_assignments.create!(role: "admin")
    admin_token = Session.issue_for(admin_user, ip: "127.0.0.1", user_agent: "Test")

    post "/api/v1/customer/tickets",
      headers: json_headers(customer_token),
      params: { subject: "Ajuda no pedido", initial_message: "Preciso de ajuda." }.to_json
    assert_response :created
    ticket_id = JSON.parse(response.body).dig("data", "id")

    get "/api/v1/admin/tickets/#{ticket_id}", headers: json_headers(admin_token)
    assert_response :ok
    assert_equal "Ajuda no pedido", JSON.parse(response.body).dig("data", "subject")

    post "/api/v1/admin/tickets/#{ticket_id}/messages",
      headers: json_headers(admin_token),
      params: { body: "Estamos analisando." }.to_json
    assert_response :created

    post "/api/v1/admin/tickets/#{ticket_id}/start_progress", headers: json_headers(admin_token)
    assert_response :ok
    assert_equal "in_progress", JSON.parse(response.body).dig("data", "state")

    post "/api/v1/admin/tickets/#{ticket_id}/resolve", headers: json_headers(admin_token)
    assert_response :ok
    assert_equal "resolved", JSON.parse(response.body).dig("data", "state")

    get "/api/v1/customer/tickets/#{ticket_id}", headers: json_headers(customer_token)
    assert_response :ok
    shown = JSON.parse(response.body)
    assert_equal "resolved", shown.dig("data", "state")
    assert_equal [ "customer", "admin" ], shown.dig("data", "messages").map { |message| message.fetch("sender_role") }
  end

  private

  def json_headers(token)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end
