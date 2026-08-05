class Cart < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :customer
  belongs_to :seller, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
