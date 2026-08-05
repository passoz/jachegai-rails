class TicketSerializer
  def self.as_json(ticket, include_messages: true)
    data = {
      id: ticket.id,
      customer_id: ticket.customer_id,
      order_id: ticket.order_id,
      subject: ticket.subject,
      state: ticket.state,
      created_at: ticket.created_at.iso8601,
      updated_at: ticket.updated_at.iso8601
    }

    if include_messages
      messages = if ticket.association(:ticket_messages).loaded?
        ticket.ticket_messages.sort_by { |message| [ message.created_at, message.id ] }
      else
        ticket.ticket_messages.order(:created_at, :id).to_a
      end
      data[:messages] = messages.map { |message| message_as_json(message) }
    end

    data
  end

  def self.message_as_json(message)
    {
      id: message.id,
      ticket_id: message.ticket_id,
      sender_id: message.sender_id,
      sender_role: message.sender_role,
      body: message.body,
      created_at: message.created_at.iso8601
    }
  end
end
