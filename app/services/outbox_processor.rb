class OutboxProcessor
  LEASE_TIMEOUT = 5.minutes
  MAX_BACKOFF = 15.minutes

  def initialize(handlers:, logger: Rails.logger)
    @handlers = handlers
    @logger = logger
  end

  def process(event_id)
    event = claim(event_id)
    return false unless event

    handler = @handlers[event.event_type]
    unless handler
      @logger.error({ event: "outbox_unknown_event", outbox_event_id: event.id, event_type: event.event_type }.to_json)
      return fail_event(event, "unknown event type: #{event.event_type}")
    end

    payload = JSON.parse(event.payload)
    handler.call(event, payload)
    event.update!(state: "completed", completed_at: Time.current, locked_at: nil, last_error: nil)
    true
  rescue StandardError => error
    fail_event(event, "#{error.class}: #{error.message}") if event
    false
  end

  private

  def claim(event_id)
    claimed = nil
    OutboxEvent.transaction do
      event = OutboxEvent.lock.find(event_id)
      return nil if %w[completed dead_letter].include?(event.state)
      return nil if event.available_at > Time.current
      return nil if event.state == "processing" && event.locked_at && event.locked_at >= LEASE_TIMEOUT.ago

      event.update!(state: "processing", locked_at: Time.current, attempts: event.attempts + 1)
      claimed = event
    end
    claimed
  end

  def fail_event(event, message)
    state = event.attempts >= event.max_attempts ? "dead_letter" : "pending"
    delay = [ 2**event.attempts, MAX_BACKOFF.to_i ].min.seconds
    event.update_columns(
      state: state,
      last_error: message.to_s.first(2_000),
      available_at: Time.current + delay,
      locked_at: nil,
      updated_at: Time.current
    )
    false
  end
end
