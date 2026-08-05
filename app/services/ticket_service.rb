class TicketService
  def initialize(principal)
    @principal = principal
  end

  def create_ticket(subject:, initial_message:, order_id: nil)
    customer = customer!
    order = resolve_order(customer, order_id)

    Ticket.transaction do
      ticket = Ticket.create!(
        customer: customer,
        order: order,
        subject: subject,
        state: "open"
      )

      TicketMessage.create!(
        ticket: ticket,
        sender: @principal.user,
        sender_role: "customer",
        body: initial_message
      )

      ticket
    end
  end

  def add_customer_message(ticket_id:, body:)
    customer = customer!
    ticket = customer.tickets.find(ticket_id)
    ensure_ticket_accepts_messages!(ticket)

    TicketMessage.create!(
      ticket: ticket,
      sender: @principal.user,
      sender_role: "customer",
      body: body
    )
  end

  private

  def customer!
    unless @principal&.has_role?("customer")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    customer = @principal.user.customer
    raise ActiveRecord::RecordNotFound, "Customer profile not found" unless customer

    customer
  end

  def resolve_order(customer, order_id)
    return nil if order_id.blank?

    Order.find_by!(id: order_id, customer_id: customer.id)
  end

  def ensure_ticket_accepts_messages!(ticket)
    return unless ticket.state == "closed"

    raise DomainError.new(
      code: :ticket_closed,
      message: "Ticket is closed",
      http_status: :conflict
    )
  end
end
