require "test_helper"

class TicketMessageTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "ticket.message.customer@example.com", password: "password123", full_name: "Ticket Message Customer")
    @customer_user.role_assignments.create!(role: "customer")
    @ticket = Ticket.create!(customer: @customer_user.customer, subject: "Ajuda", state: "open")
  end

  test "persists ticket message with sender and timestamps" do
    message = TicketMessage.create!(
      ticket: @ticket,
      sender: @customer_user,
      sender_role: "customer",
      body: "Preciso de ajuda com meu pedido."
    )

    assert message.id.present?
    assert_equal @ticket.id, message.ticket_id
    assert_equal @customer_user.id, message.sender_id
    assert_equal "customer", message.sender_role
    assert_equal "Preciso de ajuda com meu pedido.", message.body
    assert message.created_at.present?
    assert message.updated_at.present?
  end

  test "ticket messages are append-only" do
    message = TicketMessage.create!(
      ticket: @ticket,
      sender: @customer_user,
      sender_role: "customer",
      body: "Mensagem original."
    )

    refute message.update(body: "Mensagem adulterada.")
    assert_equal "Mensagem original.", message.reload.body
    refute message.destroy
    assert TicketMessage.exists?(message.id)
  end
end
