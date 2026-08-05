class Payment < ApplicationRecord
  include ServerGeneratedId

  STATES = %w[pending paid failed refunded].freeze
  AUTHORITATIVE_ATTRIBUTES = %i[order_id method provider external_reference amount_cents currency].freeze

  attr_readonly(*AUTHORITATIVE_ATTRIBUTES)

  belongs_to :order

  validates :order_id, uniqueness: true
  validates :state, inclusion: { in: STATES }
  validates :method, :provider, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :external_reference, uniqueness: true, allow_nil: true
  validate :amount_and_currency_match_order

  private

  def amount_and_currency_match_order
    return unless order

    errors.add(:amount_cents, "must match order total") unless amount_cents == order.total_cents
    errors.add(:currency, "must match order currency") unless currency == order.currency
  end
end
