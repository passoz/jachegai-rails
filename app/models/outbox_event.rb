class OutboxEvent < ApplicationRecord
  include ServerGeneratedId

  STATES = %w[pending processing completed dead_letter].freeze
  FACT_ATTRIBUTES = %i[event_key event_type aggregate_type aggregate_id payload max_attempts].freeze

  attr_readonly(*FACT_ATTRIBUTES)

  validates :event_key, :event_type, :aggregate_type, :aggregate_id, :payload, :available_at, presence: true
  validates :event_key, uniqueness: true
  validates :state, inclusion: { in: STATES }
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_attempts, numericality: { only_integer: true, greater_than: 0 }
end
