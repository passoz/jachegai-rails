class SellerMembership < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller
  belongs_to :user

  SELLER_ROLES = %w[owner manager].freeze

  validates :role, inclusion: { in: SELLER_ROLES }
  validates :user_id, uniqueness: true

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
