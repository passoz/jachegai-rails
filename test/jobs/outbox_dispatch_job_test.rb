require "test_helper"

class OutboxDispatchJobTest < ActiveJob::TestCase
  test "production schedule dispatches durable outbox events" do
    schedule = YAML.safe_load_file(Rails.root.join("config", "recurring.yml"))
    dispatch = schedule.fetch("production").fetch("outbox_dispatch")

    assert_equal "OutboxDispatchJob", dispatch.fetch("class")
    assert dispatch.fetch("schedule").present?
  end

  test "job completes available known events and ignores future events" do
    available = create_event("available", available_at: 1.second.ago)
    future = create_event("future", available_at: 1.hour.from_now)

    OutboxDispatchJob.perform_now

    assert_equal "completed", available.reload.state
    assert_equal 1, available.attempts
    assert_equal "pending", future.reload.state
    assert_equal 0, future.attempts

    OutboxDispatchJob.perform_now
    assert_equal 1, available.reload.attempts
  end

  private

  def create_event(key, available_at:)
    OutboxEvent.create!(
      event_key: key,
      event_type: "order.created",
      aggregate_type: "Order",
      aggregate_id: ApplicationId.generate,
      payload: JSON.generate(order_id: ApplicationId.generate),
      available_at: available_at
    )
  end
end
