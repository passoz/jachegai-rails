class CourierModerationService
  def initialize(principal)
    @principal = principal
  end

  def approve!(courier_id, reason: nil, correlation_id: nil)
    transition!(courier_id, target_state: "approved", valid_from: %w[pending_review], action: "courier.approve", reason: reason, correlation_id: correlation_id)
  end

  def reject!(courier_id, reason: nil, correlation_id: nil)
    transition!(courier_id, target_state: "rejected", valid_from: %w[pending_review], action: "courier.reject", reason: reason, correlation_id: correlation_id, force_offline: true)
  end

  def suspend!(courier_id, reason: nil, correlation_id: nil)
    transition!(courier_id, target_state: "suspended", valid_from: %w[approved], action: "courier.suspend", reason: reason, correlation_id: correlation_id, force_offline: true)
  end

  def reinstate!(courier_id, reason: nil, correlation_id: nil)
    transition!(courier_id, target_state: "approved", valid_from: %w[suspended], action: "courier.reinstate", reason: reason, correlation_id: correlation_id)
  end

  private

  def transition!(courier_id, target_state:, valid_from:, action:, reason:, correlation_id:, force_offline: false)
    unless @principal&.admin?
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    failure_recorded = false
    courier = Courier.find(courier_id)
    unless valid_from.include?(courier.moderation_state)
      record_failure!(
        courier: courier,
        action: action,
        target_state: target_state,
        reason: reason,
        correlation_id: correlation_id
      )
      failure_recorded = true
      raise DomainError.new(
        code: :invalid_transition,
        message: "Cannot transition courier from #{courier.moderation_state} to #{target_state}",
        http_status: :conflict
      )
    end

    Courier.transaction do
      courier.lock!
      previous_state = courier.moderation_state
      unless valid_from.include?(previous_state)
        raise DomainError.new(
          code: :invalid_transition,
          message: "Cannot transition courier from #{previous_state} to #{target_state}",
          http_status: :conflict
        )
      end

      courier.moderation_state = target_state
      courier.operational_state = "offline" if force_offline
      courier.save!

      AuditRecord.record!(
        actor: @principal,
        action: action,
        resource_type: "Courier",
        resource_id: courier.id,
        reason: reason,
        correlation_id: correlation_id,
        metadata: JSON.generate(
          previous_state: previous_state,
          new_state: target_state
        )
      )
    end

    courier
  rescue DomainError => error
    if error.code == "invalid_transition" && courier&.persisted? && !failure_recorded
      record_failure!(
        courier: courier,
        action: action,
        target_state: target_state,
        reason: reason,
        correlation_id: correlation_id
      )
    end
    raise
  end

  def record_failure!(courier:, action:, target_state:, reason:, correlation_id:)
    AuditRecord.record!(
      actor: @principal,
      action: action,
      resource_type: "Courier",
      resource_id: courier.id,
      result: "failure",
      reason: reason,
      correlation_id: correlation_id,
      metadata: JSON.generate(
        current_state: courier.moderation_state,
        target_state: target_state
      )
    )
  end
end
