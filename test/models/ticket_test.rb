require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "ticket.customer@example.com", password: "password123", full_name: "Ticket Customer")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer
  end

  test "persists support ticket with optional order, state and timestamps" do
    ticket = Ticket.create!(
      customer: @customer,
      subject: "Pedido atrasado",
      state: "open"
    )

    assert ticket.id.present?
    assert_nil ticket.order_id
    assert_equal @customer.id, ticket.customer_id
    assert_equal "Pedido atrasado", ticket.subject
    assert_equal "open", ticket.state
    assert ticket.created_at.present?
    assert ticket.updated_at.present?
  end
end
