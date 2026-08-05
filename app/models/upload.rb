class Upload < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :owner, polymorphic: true

  validates :storage_key, presence: true, uniqueness: true
  validates :filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
