class InventoryItem < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: true
  validate :product_belongs_to_seller

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def product_belongs_to_seller
    return if product_id.blank?

    errors.add(:product_id, "must belong to the seller") unless product&.seller_id == seller_id
  end
end
