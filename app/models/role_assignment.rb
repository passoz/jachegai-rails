class RoleAssignment < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id
  after_create :ensure_customer_profile

  belongs_to :user

  ROLES = %w[customer seller courier admin].freeze

  validates :role, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: :user_id }

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def ensure_customer_profile
    return unless role == "customer"

    user.create_customer!(full_name: user.full_name) unless user.customer
  end
end
