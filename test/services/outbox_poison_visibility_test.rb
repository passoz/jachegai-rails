require "test_helper"

class OutboxPoisonVisibilityTest < ActiveSupport::TestCase
  setup do
    @event = OutboxEvent.create!(
      event_key: "poison:visible:1", event_type: "known.event", aggregate_type: "Order",
      aggregate_id: ApplicationId.generate, payload: "{}", available_at: 1.second.ago,
      max_attempts: 2
    )
  end

  test "bounded retry leads to terminal dead_letter visible for operator action" do
    processor = OutboxProcessor.new(handlers: { "known.event" => ->(*) { raise "poison" } })

    # First attempt: retry (pending) with backoff
    refute processor.process(@event.id)
    assert_equal "pending", @event.reload.state
    assert_equal 1, @event.attempts
    assert_includes @event.last_error, "poison"

    # Second attempt (after backoff elapses): dead_letter terminal
    @event.update_columns(available_at: 1.second.ago)
    refute processor.process(@event.id)
    assert_equal "dead_letter", @event.reload.state
    assert_equal 2, @event.attempts

    # Terminal poison state is visible: no further retries possible
    @event.update_columns(available_at: 1.second.ago)
    refute processor.process(@event.id)
    assert_equal "dead_letter", @event.reload.state
    assert_equal 2, @event.attempts, "must not increment attempts after dead_letter"
  end
end
