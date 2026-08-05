require "test_helper"

class TicketStateTest < ActiveSupport::TestCase
  test "allows canonical ticket state transitions" do
    assert_equal "in_progress", TicketState.transition!("open", :start_progress)
    assert_equal "resolved", TicketState.transition!("in_progress", :resolve)
    assert_equal "open", TicketState.transition!("resolved", :reopen)
    assert_equal "open", TicketState.transition!("closed", :reopen)
    assert_equal "closed", TicketState.transition!("open", :close)
    assert_equal "closed", TicketState.transition!("in_progress", :close)
    assert_equal "closed", TicketState.transition!("resolved", :close)
  end

  test "rejects invalid ticket state transitions" do
    error = assert_raises DomainError do
      TicketState.transition!("open", :resolve)
    end
    assert_equal "invalid_ticket_transition", error.code

    error = assert_raises DomainError do
      TicketState.transition!("closed", :start_progress)
    end
    assert_equal "invalid_ticket_transition", error.code

    error = assert_raises DomainError do
      TicketState.transition!("in_progress", :unknown)
    end
    assert_equal "invalid_ticket_transition", error.code
  end
end
