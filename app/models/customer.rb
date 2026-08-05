class Customer < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :user
  has_many :addresses, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error

  validates :full_name, presence: true
  validates :user_id, uniqueness: true

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
