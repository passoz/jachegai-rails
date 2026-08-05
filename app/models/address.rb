class Address < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :customer
  has_many :orders, foreign_key: :source_address_id, dependent: :nullify, inverse_of: :source_address

  validates :name, :line1, :city, :state, :zip, :country, presence: true

  before_save :ensure_single_default

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def ensure_single_default
    if is_default? && is_default_changed?
      transaction do
        customer.addresses.where.not(id: id).update_all(is_default: false)
      end
    end
  end
end
