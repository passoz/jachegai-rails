class Courier < ApplicationRecord
  include ServerGeneratedId

  MODERATION_STATES = %w[pending_review approved rejected suspended].freeze
  OPERATIONAL_STATES = %w[offline available on_delivery].freeze
  VEHICLE_TYPES = %w[motorcycle bicycle car foot].freeze

  belongs_to :user
  has_many :orders, foreign_key: :courier_id, dependent: :nullify

  validates :phone, presence: true
  validates :document_number, presence: true, uniqueness: true
  validates :vehicle_type, presence: true, inclusion: { in: VEHICLE_TYPES }
  validates :moderation_state, presence: true, inclusion: { in: MODERATION_STATES }
  validates :operational_state, presence: true, inclusion: { in: OPERATIONAL_STATES }
  validates :user_id, uniqueness: true
  validate :unapproved_courier_is_offline

  def approved?
    moderation_state == "approved"
  end

  def available?
    operational_state == "available"
  end

  def on_delivery?
    operational_state == "on_delivery"
  end

  def offline?
    operational_state == "offline"
  end

  private

  def unapproved_courier_is_offline
    return if approved? || offline?

    errors.add(:operational_state, "must be offline unless the courier is approved")
  end
end
