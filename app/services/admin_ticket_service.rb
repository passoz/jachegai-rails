class AdminTicketService
  def initialize(principal)
    @principal = principal
  end

  def add_message(ticket_id:, body:)
    require_admin!
    ticket = Ticket.find(ticket_id)

    TicketMessage.create!(
      ticket: ticket,
      sender: @principal.user,
      sender_role: "admin",
      body: body
    )
  end

  def transition(ticket_id:, action:)
    require_admin!
    ticket = Ticket.find(ticket_id)

    Ticket.transaction do
      next_state = TicketState.transition!(ticket.state, action)
      ticket.update!(state: next_state)
      AuditRecord.record!(
        actor: @principal,
        action: "ticket.#{action}",
        resource_type: "Ticket",
        resource_id: ticket.id,
        result: "success"
      )
      ticket
    end
  end

  private

  def require_admin!
    raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden) unless @principal&.admin?
  end
end
