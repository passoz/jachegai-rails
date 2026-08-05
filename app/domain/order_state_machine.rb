class OrderStateMachine
  STATES = %w[pending accepted rejected preparing ready assigned picked_up delivered cancelled].freeze
  TERMINAL_STATES = %w[rejected delivered cancelled].freeze

  TRANSITIONS = {
    "pending" => %w[accepted rejected cancelled],
    "accepted" => %w[preparing cancelled],
    "preparing" => %w[ready],
    "ready" => %w[assigned],
    "assigned" => %w[picked_up cancelled],
    "picked_up" => %w[delivered]
  }.freeze

  def self.transition_allowed?(from:, to:)
    return false unless STATES.include?(from) && STATES.include?(to)
    return false if TERMINAL_STATES.include?(from)

    allowed = TRANSITIONS[from] || []
    allowed.include?(to)
  end
end
