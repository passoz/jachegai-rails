require "test_helper"

class Api::V1::Customer::TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "customer.ticket.http@example.com", password: "password123", full_name: "Customer Ticket HTTP")
    @customer_user.role_assignments.create!(role: "customer")
    @token = Session.issue_for(@customer_user, ip: "127.0.0.1", user_agent: "Test")
  end

  test "customer creates lists and shows own tickets" do
    post "/api/v1/customer/tickets",
      headers: auth_headers,
      params: { subject: "Pedido atrasado", initial_message: "Meu pedido atrasou." }.to_json

    assert_response :created
    created = JSON.parse(response.body)
    assert created["ok"]
    ticket_id = created.dig("data", "id")
    assert ticket_id.present?
    assert_equal "open", created.dig("data", "state")
    assert_equal "Pedido atrasado", created.dig("data", "subject")
    assert_equal 1, created.dig("data", "messages").size

    get "/api/v1/customer/tickets", headers: auth_headers

    assert_response :ok
    listed = JSON.parse(response.body)
    assert_equal [ ticket_id ], listed.fetch("data").map { |ticket| ticket.fetch("id") }

    get "/api/v1/customer/tickets/#{ticket_id}", headers: auth_headers

    assert_response :ok
    shown = JSON.parse(response.body)
    assert_equal ticket_id, shown.dig("data", "id")
    assert_equal "Meu pedido atrasou.", shown.dig("data", "messages", 0, "body")
  end

  test "other customer cannot access ticket and does not see it in list" do
    ticket = TicketService.new(Principal.new(user: @customer_user)).create_ticket(
      subject: "Privado",
      initial_message: "Mensagem privada."
    )
    other_user = User.create!(email: "other.customer.ticket.http@example.com", password: "password123", full_name: "Other Ticket HTTP")
    other_user.role_assignments.create!(role: "customer")
    other_token = Session.issue_for(other_user, ip: "127.0.0.1", user_agent: "Test")
    other_headers = { "Authorization" => "Bearer #{other_token}", "Content-Type" => "application/json" }

    get "/api/v1/customer/tickets/#{ticket.id}", headers: other_headers

    assert_response :not_found

    get "/api/v1/customer/tickets", headers: other_headers

    assert_response :ok
    assert_empty JSON.parse(response.body).fetch("data")
  end

  test "customer adds message to own non-closed ticket" do
    ticket = TicketService.new(Principal.new(user: @customer_user)).create_ticket(
      subject: "Ainda preciso de ajuda",
      initial_message: "Mensagem inicial."
    )

    post "/api/v1/customer/tickets/#{ticket.id}/messages",
      headers: auth_headers,
      params: { body: "Nova mensagem do cliente." }.to_json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Nova mensagem do cliente.", json.dig("data", "body")
    assert_equal "customer", json.dig("data", "sender_role")
    assert_equal 2, ticket.reload.ticket_messages.count
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end
end
