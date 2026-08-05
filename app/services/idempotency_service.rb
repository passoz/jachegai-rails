class IdempotencyService
  CLAIM_TIMEOUT = 5.minutes
  LOCK_RETRY_DELAYS = [ 0.01, 0.025, 0.05, 0.1 ].freeze

  def self.execute(principal_id:, operation:, key:, payload:)
    request_digest = digest(payload)
    record, claimed = claim(principal_id: principal_id, operation: operation, key: key, request_digest: request_digest)
    return load_resource(record) unless claimed

    yield(record)
  rescue DomainError => e
    fail_record(record, e.code) if record&.persisted? && record.state != "completed"
    raise
  rescue StandardError
    fail_record(record, "internal_failure") if record&.persisted? && record.state != "completed"
    raise
  end

  def self.complete!(record, resource:, response_status:, response_body: nil)
    record.update!(
      state: "completed",
      resource_type: resource.class.base_class.name,
      resource_id: resource.id,
      response_status: response_status,
      response_body: response_body && JSON.generate(response_body),
      completed_at: Time.current,
      last_error_code: nil
    )
  end

  def self.digest(payload)
    Digest::SHA256.hexdigest(JSON.generate(canonicalize(payload)))
  end

  def self.claim(principal_id:, operation:, key:, request_digest:)
    record = nil
    created = false

    with_sqlite_lock_retry do
      begin
        record = IdempotencyRecord.create!(
          principal_id: principal_id,
          operation: operation,
          key: key,
          request_digest: request_digest,
          state: "processing",
          locked_at: Time.current
        )
        created = true
      rescue ActiveRecord::RecordNotUnique
        record = IdempotencyRecord.find_by!(principal_id: principal_id, operation: operation, key: key)
      end
    end

    return [ record, true ] if created
    raise conflict("payload_mismatch") unless ActiveSupport::SecurityUtils.secure_compare(record.request_digest, request_digest)
    return [ record, false ] if record.state == "completed"

    if record.state == "failed" || record.locked_at.nil? || record.locked_at < CLAIM_TIMEOUT.ago
      record.update!(state: "processing", locked_at: Time.current, last_error_code: nil)
      return [ record, true ]
    end

    raise conflict("in_progress")
  end
  private_class_method :claim

  def self.load_resource(record)
    type = record.resource_type.to_s.safe_constantize
    raise DomainError.new(code: :internal_failure, http_status: :internal_server_error) unless type&.<=(ApplicationRecord)

    type.find(record.resource_id)
  end
  private_class_method :load_resource

  def self.fail_record(record, code)
    record.update_columns(state: "failed", last_error_code: code, locked_at: nil, updated_at: Time.current)
  rescue ActiveRecord::ActiveRecordError
    Rails.logger.error({ event: "idempotency_failure_not_recorded", idempotency_record_id: record.id }.to_json)
  end
  private_class_method :fail_record

  def self.conflict(reason)
    DomainError.new(code: :idempotency_conflict, context: { reason: reason })
  end
  private_class_method :conflict

  def self.with_sqlite_lock_retry
    attempts = 0
    begin
      yield
    rescue ActiveRecord::StatementTimeout => error
      raise unless sqlite_locked?(error) && attempts < LOCK_RETRY_DELAYS.length

      sleep(LOCK_RETRY_DELAYS.fetch(attempts))
      attempts += 1
      retry
    end
  end
  private_class_method :with_sqlite_lock_retry

  def self.sqlite_locked?(error)
    cause = error.cause
    cause&.class&.name == "SQLite3::BusyException" || error.message.include?("database is locked")
  end
  private_class_method :sqlite_locked?

  def self.canonicalize(value)
    case value
    when Hash
      value.to_h.transform_keys(&:to_s).sort.to_h.transform_values { |nested| canonicalize(nested) }
    when Array
      value.map { |nested| canonicalize(nested) }
    else
      value
    end
  end
  private_class_method :canonicalize
end
