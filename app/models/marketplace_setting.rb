class MarketplaceSetting < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  validates :key, presence: true
  validates :value, presence: true
  validates :effective_at, presence: true
  validates :actor_id, presence: true

  def self.get(key, at: Time.current)
    where("key = ? AND effective_at <= ?", key, at)
      .order(effective_at: :desc, created_at: :desc)
      .first
      &.value
  end

  def self.set!(key:, value:, actor:, effective_at: Time.current, reason: nil)
    create!(
      key: key,
      value: value.to_s,
      effective_at: effective_at,
      actor_id: actor.respond_to?(:id) ? actor.id : actor.to_s,
      reason: reason
    )
  end

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
