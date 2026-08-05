# AuditRecord stores immutable evidence for sensitive operations (ADM-009,
# SEL-012). Records are append-only: persisted rows cannot be updated or
# destroyed through the application.
class AuditRecord < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id
  before_destroy :prevent_destroy

  RESULTS = %w[success failure].freeze

  validates :actor_principal_id, presence: true
  validates :action, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true
  validates :result, presence: true, inclusion: { in: RESULTS }

  alias_attribute :request_id, :correlation_id

  def readonly?
    !new_record?
  end

  def self.record!(actor:, action:, resource_type:, resource_id:, result: "success", reason: nil, correlation_id: nil, request_id: nil, metadata: nil)
    create!(
      actor_principal_id: actor.respond_to?(:id) ? actor.id : actor.to_s,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      result: result,
      reason: reason,
      correlation_id: request_id || correlation_id,
      metadata: metadata
    )
  end

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "AuditRecord is read-only and cannot be destroyed"
  end
end
