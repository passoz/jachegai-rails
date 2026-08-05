# Network policy for external provider adapters.
#
# INT-003/NFR-008/NFR-009: every external request MUST use explicit timeouts
# and bounded retries appropriate to idempotency. Adapters should use these
# constants instead of hardcoding their own; this keeps the bounds consistent
# and auditable.
module NetworkPolicy
  DEFAULT_TIMEOUT_SECONDS = 5

  # Maximum total retries for idempotent operations.
  MAX_RETRIES = 3

  # Base backoff in seconds; exponential with jitter.
  BASE_BACKOFF_SECONDS = 1

  # Upper bound for backoff so retries never spin unboundedly.
  MAX_BACKOFF_SECONDS = 30

  def self.timeout_seconds(configured: nil)
    (configured || DEFAULT_TIMEOUT_SECONDS).to_i
  end

  def self.retry_delay(attempt)
    [ BASE_BACKOFF_SECONDS * (2**(attempt - 1)), MAX_BACKOFF_SECONDS ].min
  end

  def self.with_bounded_retries(max_retries: MAX_RETRIES)
    attempt = 0
    begin
      attempt += 1
      yield(attempt)
    rescue StandardError => error
      raise if attempt >= max_retries

      sleep(retry_delay(attempt))
      retry
    end
  end
end
