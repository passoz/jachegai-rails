class SellerSettings < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller

  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :preparation_time_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
