# SellerModeration is a pure state machine for seller moderation states
# (spec §8.1). It is independent of HTTP and Active Record so the transition
# table can be unit-tested in isolation and reused by ModerationService.
class SellerModeration
  STATES = %w[pending_review approved suspended rejected].freeze

  TRANSITIONS = {
    "pending_review" => {
      "approve" => "approved",
      "reject" => "rejected"
    },
    "approved" => {
      "suspend" => "suspended"
    },
    "suspended" => {
      "reinstate" => "approved"
    }
  }.freeze

  class InvalidTransition < StandardError; end

  def self.states
    STATES
  end

  def self.actions_for(state)
    TRANSITIONS.fetch(state.to_s, {}).keys
  end

  # Returns the destination state for the given action, raising
  # InvalidTransition when the action is not allowed from the current state.
  def self.transition(state, action)
    new_state = TRANSITIONS.dig(state.to_s, action.to_s)
    raise InvalidTransition, "invalid transition: #{state} -> #{action}" unless new_state

    new_state
  end
end
