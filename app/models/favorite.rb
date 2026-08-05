class Favorite < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :customer
  belongs_to :seller

  validates :seller_id, uniqueness: { scope: :customer_id, message: "vendedor já favoritado" }
  validate :seller_must_be_approved

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def seller_must_be_approved
    if seller && seller.moderation_state != "approved"
      errors.add(:seller, "deve estar aprovado para ser favoritado")
    end
  end
end
