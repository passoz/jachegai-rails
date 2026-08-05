class CartItem < ApplicationRecord
  self.primary_key = "id"

  MAX_QUANTITY = 100

  before_create :set_id

  belongs_to :cart
  belongs_to :product
  belongs_to :seller

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_QUANTITY }
  validate :product_active_and_seller_approved
  validate :product_belongs_to_cart_seller
  validate :currency_matches_cart
  validate :quantity_within_available_stock

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def product_active_and_seller_approved
    return unless product

    unless product.active?
      errors.add(:product, "deve estar ativo")
    end

    if product.seller && product.seller.moderation_state != "approved"
      errors.add(:product, "vendedor deve estar aprovado")
    end
  end

  def product_belongs_to_cart_seller
    return unless product && cart

    if cart.seller_id.present? && product.seller_id != cart.seller_id
      errors.add(:product, "must belong to the cart seller")
    end
  end

  def currency_matches_cart
    return unless product && cart

    other_currencies = cart.cart_items.where.not(id: id).joins(:product).distinct.pluck("products.currency")
    return if other_currencies.empty? || other_currencies == [ product.currency ]

    errors.add(:product, "currency must match the cart currency")
  end

  def quantity_within_available_stock
    return unless product && quantity

    stock = product.inventory_item&.quantity || 0
    if quantity > stock
      errors.add(:quantity, "must be less than or equal to available stock (#{stock})")
    end
  end
end
