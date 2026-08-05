class IdempotencyRecord < ApplicationRecord
  include ServerGeneratedId

  STATES = %w[processing completed failed].freeze

  validates :principal_id, :operation, :key, :request_digest, presence: true
  validates :state, inclusion: { in: STATES }
end
