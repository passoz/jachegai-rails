class Invoice < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller

  STATES = %w[pending paid cancelled].freeze

  validates :seller_id, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :gross_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :fee_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :net_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :state, presence: true, inclusion: { in: STATES }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
