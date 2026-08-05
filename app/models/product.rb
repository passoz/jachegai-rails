class Product < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller
  belongs_to :category, optional: true
  has_one :inventory_item, dependent: :restrict_with_error
  has_many :order_items, dependent: :nullify
  has_many :inventory_movements, dependent: :restrict_with_error
  has_many :uploads, as: :owner, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 140 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validate :category_belongs_to_seller

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(created_at: :desc, id: :desc) }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def category_belongs_to_seller
    return if category_id.blank?

    errors.add(:category_id, "must belong to the product's seller") unless category&.seller_id == seller_id
  end
end
