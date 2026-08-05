class OrderItem < ApplicationRecord
  include ServerGeneratedId
  include AppendOnlyRecord

  belongs_to :order
  belongs_to :product, optional: true
  belongs_to :seller

  validates :product_name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: CartItem::MAX_QUANTITY }
  validates :unit_price_cents, :subtotal_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validate :subtotal_is_consistent
  validate :currency_matches_order

  private

  def subtotal_is_consistent
    return unless unit_price_cents.is_a?(Integer) && quantity.is_a?(Integer)

    errors.add(:subtotal_cents, "must match unit price and quantity") unless subtotal_cents == unit_price_cents * quantity
  end

  def currency_matches_order
    return unless order && currency

    errors.add(:currency, "must match order currency") unless currency == order.currency
  end
end
