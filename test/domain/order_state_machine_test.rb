require "test_helper"

class OrderStateMachineTest < ActiveSupport::TestCase
  test "canonical transitions are valid" do
    assert OrderStateMachine.transition_allowed?(from: "pending", to: "accepted")
    assert OrderStateMachine.transition_allowed?(from: "pending", to: "rejected")
    assert OrderStateMachine.transition_allowed?(from: "pending", to: "cancelled")

    assert OrderStateMachine.transition_allowed?(from: "accepted", to: "preparing")
    assert OrderStateMachine.transition_allowed?(from: "accepted", to: "cancelled")

    assert OrderStateMachine.transition_allowed?(from: "preparing", to: "ready")

    assert OrderStateMachine.transition_allowed?(from: "ready", to: "assigned")

    assert OrderStateMachine.transition_allowed?(from: "assigned", to: "picked_up")
    assert OrderStateMachine.transition_allowed?(from: "assigned", to: "cancelled")

    assert OrderStateMachine.transition_allowed?(from: "picked_up", to: "delivered")
  end

  test "invalid transitions are rejected" do
    # Cannot jump steps
    refute OrderStateMachine.transition_allowed?(from: "pending", to: "preparing")
    refute OrderStateMachine.transition_allowed?(from: "pending", to: "ready")
    refute OrderStateMachine.transition_allowed?(from: "pending", to: "delivered")

    # Cannot transition backward
    refute OrderStateMachine.transition_allowed?(from: "accepted", to: "pending")
    refute OrderStateMachine.transition_allowed?(from: "preparing", to: "accepted")
    refute OrderStateMachine.transition_allowed?(from: "ready", to: "preparing")
    refute OrderStateMachine.transition_allowed?(from: "assigned", to: "ready")
    refute OrderStateMachine.transition_allowed?(from: "picked_up", to: "assigned")

    # Cancellation windows must match the canonical table exactly.
    refute OrderStateMachine.transition_allowed?(from: "preparing", to: "cancelled")
    refute OrderStateMachine.transition_allowed?(from: "ready", to: "cancelled")
  end

  test "terminal states cannot transition" do
    OrderStateMachine::TERMINAL_STATES.each do |state|
      (OrderStateMachine::STATES - [ state ]).each do |to_state|
        refute OrderStateMachine.transition_allowed?(from: state, to: to_state), "terminal state #{state} must not transition to #{to_state}"
      end
    end
  end
end
