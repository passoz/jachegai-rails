require "test_helper"

class TicketServiceTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "ticket.service.customer@example.com", password: "password123", full_name: "Ticket Service Customer")
    @customer_user.role_assignments.create!(role: "customer")
    @principal = Principal.new(user: @customer_user)
  end

  test "creates ticket and initial message atomically" do
    ticket = nil

    assert_difference -> { Ticket.count }, 1 do
      assert_difference -> { TicketMessage.count }, 1 do
        ticket = TicketService.new(@principal).create_ticket(
          subject: "Pedido atrasado",
          initial_message: "Meu pedido ainda não chegou."
        )
      end
    end

    assert_equal @customer_user.customer.id, ticket.customer_id
    assert_equal "open", ticket.state
    assert_equal "Pedido atrasado", ticket.subject
    message = ticket.ticket_messages.first
    assert_equal @customer_user.id, message.sender_id
    assert_equal "customer", message.sender_role
    assert_equal "Meu pedido ainda não chegou.", message.body
  end

  test "optional order must belong to authenticated customer" do
    other_user = User.create!(email: "ticket.service.other@example.com", password: "password123", full_name: "Other Customer")
    other_user.role_assignments.create!(role: "customer")
    seller = Seller.create!(name: "Ticket Store", moderation_state: "approved")
    other_order = Order.create!(
      customer: other_user.customer,
      seller: seller,
      status: "pending",
      currency: "BRL",
      subtotal_cents: 1000,
      delivery_fee_cents: 500,
      discount_cents: 0,
      total_cents: 1500,
      address_name: "Casa",
      address_line1: "Rua A",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )

    assert_no_difference -> { Ticket.count } do
      assert_no_difference -> { TicketMessage.count } do
        assert_raises ActiveRecord::RecordNotFound do
          TicketService.new(@principal).create_ticket(
            subject: "Pedido alheio",
            initial_message: "Quero abrir ticket em pedido alheio.",
            order_id: other_order.id
          )
        end
      end
    end
  end

  test "initial message failure rolls back ticket creation" do
    assert_no_difference -> { Ticket.count } do
      assert_no_difference -> { TicketMessage.count } do
        assert_raises ActiveRecord::RecordInvalid do
          TicketService.new(@principal).create_ticket(
            subject: "Mensagem falha",
            initial_message: nil
          )
        end
      end
    end
  end
end
