require "test_helper"

class OutboxProcessorTest < ActiveSupport::TestCase
  setup do
    @event = OutboxEvent.create!(
      event_key: "test:1", event_type: "known.event", aggregate_type: "Order",
      aggregate_id: ApplicationId.generate, payload: JSON.generate(value: 1), available_at: Time.current,
      max_attempts: 2
    )
  end

  test "event facts are readonly while delivery state remains mutable" do
    assert_raises ActiveRecord::ReadonlyAttributeError do
      @event.update!(event_type: "changed.event", payload: "{}")
    end
    @event.update!(available_at: 1.minute.from_now)

    assert_equal "known.event", @event.reload.event_type
    assert_equal JSON.generate(value: 1), @event.payload
    assert_operator @event.available_at, :>, Time.current
  end

  test "processes a known event once and completed retry is a no-op" do
    calls = 0
    processor = OutboxProcessor.new(handlers: { "known.event" => ->(_event, payload) {
      calls += 1
      assert_equal 1, payload.fetch("value")
    } })

    assert processor.process(@event.id)
    refute processor.process(@event.id)

    assert_equal 1, calls
    assert_equal "completed", @event.reload.state
    assert_equal 1, @event.attempts
    assert_not_nil @event.completed_at
  end

  test "failure records attempts error and retry state then dead letters poison work" do
    processor = OutboxProcessor.new(handlers: { "known.event" => ->(*) { raise "provider failed" } })

    refute processor.process(@event.id)
    assert_equal "pending", @event.reload.state
    assert_equal 1, @event.attempts
    assert_includes @event.last_error, "provider failed"
    assert_operator @event.available_at, :>, Time.current

    @event.update_columns(available_at: 1.second.ago)
    refute processor.process(@event.id)
    assert_equal "dead_letter", @event.reload.state
    assert_equal 2, @event.attempts
  end

  test "unknown event is observable and never silently completed" do
    unknown = OutboxEvent.create!(
      event_key: "unknown:1", event_type: "unknown.event", aggregate_type: "Order",
      aggregate_id: ApplicationId.generate, payload: "{}", available_at: Time.current
    )
    logs = StringIO.new
    logger = ActiveSupport::Logger.new(logs)

    refute OutboxProcessor.new(handlers: {}, logger: logger).process(unknown.id)

    assert_equal "pending", unknown.reload.state
    assert_equal 1, unknown.attempts
    assert_includes unknown.last_error, "unknown event type"
    assert_includes logs.string, "outbox_unknown_event"
  end

  test "stale processing lease is recovered" do
    @event.update_columns(state: "processing", locked_at: 10.minutes.ago)
    calls = 0

    result = OutboxProcessor.new(handlers: { "known.event" => ->(*) { calls += 1 } }).process(@event.id)

    assert result
    assert_equal 1, calls
    assert_equal "completed", @event.reload.state
  end
end
