class TicketMessage < ApplicationRecord
  include ServerGeneratedId
  include AppendOnlyRecord

  SENDER_ROLES = %w[customer admin].freeze

  belongs_to :ticket
  belongs_to :sender, class_name: "User"

  validates :body, presence: true
  validates :sender_role, inclusion: { in: SENDER_ROLES }
end
