class GuestCartItem < ApplicationRecord
  MAX_QUANTITY = 100
  MUTATION_RATE_LIMIT = 5
  MUTATION_RATE_WINDOW = 60.seconds

  before_create :generate_server_id

  belongs_to :guest_cart
  belongs_to :product
  belongs_to :seller

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validate :product_belongs_to_cart_seller

  private

  def product_belongs_to_cart_seller
    return unless guest_cart && product
    return if guest_cart.seller_id.present? && guest_cart.seller_id == product.seller_id && seller_id == product.seller_id

    errors.add(:product, "must belong to the cart seller")
  end

  def generate_server_id
    self.id ||= ApplicationId.generate
  end
end
