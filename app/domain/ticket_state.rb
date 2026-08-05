class TicketState
  TRANSITIONS = {
    start_progress: {
      "open" => "in_progress"
    },
    resolve: {
      "in_progress" => "resolved"
    },
    reopen: {
      "resolved" => "open",
      "closed" => "open"
    },
    close: {
      "open" => "closed",
      "in_progress" => "closed",
      "resolved" => "closed"
    }
  }.freeze

  def self.transition!(current_state, action)
    next_state = TRANSITIONS.fetch(action.to_sym, {}).fetch(current_state, nil)
    return next_state if next_state

    raise DomainError.new(
      code: :invalid_ticket_transition,
      message: "Invalid ticket transition",
      http_status: :conflict
    )
  end
end
