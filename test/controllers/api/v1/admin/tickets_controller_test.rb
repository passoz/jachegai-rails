require "test_helper"

class Api::V1::Admin::TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(email: "admin.ticket.http@example.com", password: "password123", full_name: "Admin Ticket HTTP")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_token = Session.issue_for(@admin_user, ip: "127.0.0.1", user_agent: "Test")

    @customer_user = User.create!(email: "customer.admin.ticket.http@example.com", password: "password123", full_name: "Customer Admin Ticket HTTP")
    @customer_user.role_assignments.create!(role: "customer")
    @ticket = TicketService.new(Principal.new(user: @customer_user)).create_ticket(
      subject: "Suporte admin",
      initial_message: "Preciso de suporte."
    )
  end

  test "admin lists and details support tickets with messages" do
    get "/api/v1/admin/tickets", headers: admin_headers

    assert_response :ok
    listed = JSON.parse(response.body)
    assert_equal [ @ticket.id ], listed.fetch("data").map { |ticket| ticket.fetch("id") }

    get "/api/v1/admin/tickets/#{@ticket.id}", headers: admin_headers

    assert_response :ok
    shown = JSON.parse(response.body)
    assert_equal @ticket.id, shown.dig("data", "id")
    assert_equal "Suporte admin", shown.dig("data", "subject")
    assert_equal "Preciso de suporte.", shown.dig("data", "messages", 0, "body")
  end

  test "admin replies and transitions ticket lifecycle" do
    post "/api/v1/admin/tickets/#{@ticket.id}/messages",
      headers: admin_headers,
      params: { body: "Estamos verificando." }.to_json

    assert_response :created
    assert_equal "admin", JSON.parse(response.body).dig("data", "sender_role")

    post "/api/v1/admin/tickets/#{@ticket.id}/start_progress", headers: admin_headers
    assert_response :ok
    assert_equal "in_progress", JSON.parse(response.body).dig("data", "state")

    post "/api/v1/admin/tickets/#{@ticket.id}/resolve", headers: admin_headers
    assert_response :ok
    assert_equal "resolved", JSON.parse(response.body).dig("data", "state")

    post "/api/v1/admin/tickets/#{@ticket.id}/reopen", headers: admin_headers
    assert_response :ok
    assert_equal "open", JSON.parse(response.body).dig("data", "state")

    post "/api/v1/admin/tickets/#{@ticket.id}/close", headers: admin_headers
    assert_response :ok
    assert_equal "closed", JSON.parse(response.body).dig("data", "state")
  end

  test "admin ticket transitions are audited" do
    assert_difference -> { AuditRecord.where(resource_type: "Ticket", resource_id: @ticket.id).count }, 1 do
      post "/api/v1/admin/tickets/#{@ticket.id}/start_progress", headers: admin_headers
    end

    assert_response :ok
    audit = AuditRecord.where(resource_type: "Ticket", resource_id: @ticket.id).order(:created_at).last
    assert_equal @admin_user.id, audit.actor_principal_id
    assert_equal "ticket.start_progress", audit.action
    assert_equal "success", audit.result
  end

  private

  def admin_headers
    { "Authorization" => "Bearer #{@admin_token}", "Content-Type" => "application/json" }
  end
end
