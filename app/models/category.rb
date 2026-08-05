class Category < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :seller
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 80 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :name, uniqueness: { scope: :seller_id }
  validates :position, uniqueness: { scope: :seller_id }

  scope :ordered, -> { order(:position, :id) }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
