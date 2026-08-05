class Ticket < ApplicationRecord
  include ServerGeneratedId

  STATES = %w[open in_progress resolved closed].freeze

  belongs_to :customer
  belongs_to :order, optional: true
  has_many :ticket_messages, dependent: :restrict_with_error

  validates :subject, presence: true
  validates :state, inclusion: { in: STATES }
end
