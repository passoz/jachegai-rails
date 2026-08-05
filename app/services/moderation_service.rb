# ModerationService applies administrator-authorized seller moderation
# transitions with immutable audit evidence (ADM-003/ADM-009, SEL-002).
class ModerationService
  def self.transition(seller:, action:, actor:, reason: nil, correlation_id: nil)
    unless actor&.admin?
      record_failure!(seller:, action:, actor:, reason: reason || "administrator authority required", correlation_id:)
      raise DomainError.new(code: :forbidden, http_status: :forbidden)
    end

    new_state = SellerModeration.transition(seller.moderation_state, action)
    Seller.transaction do
      seller.update!(moderation_state: new_state, moderated_at: Time.current)
      AuditRecord.record!(
        actor: actor,
        action: action,
        resource_type: "Seller",
        resource_id: seller.id,
        result: "success",
        reason: reason,
        correlation_id: correlation_id
      )
    end
    seller
  rescue SellerModeration::InvalidTransition
    record_failure!(
      seller: seller,
      action: action,
      actor: actor,
      reason: reason || "invalid transition from #{seller&.moderation_state}",
      correlation_id: correlation_id
    )
    raise DomainError.new(
      code: :invalid_transition,
      context: { current: seller&.moderation_state, action: action }
    )
  end

  def self.record_failure!(seller:, action:, actor:, reason:, correlation_id:)
    AuditRecord.record!(
      actor: actor,
      action: action,
      resource_type: "Seller",
      resource_id: seller.id,
      result: "failure",
      reason: reason,
      correlation_id: correlation_id
    )
  end
  private_class_method :record_failure!
end
