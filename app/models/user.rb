class User < ApplicationRecord
  self.primary_key = "id"

  has_secure_password

  before_create :set_id
  before_validation :normalize_email

  has_many :role_assignments, dependent: :destroy
  has_one :customer, dependent: :destroy
  has_one :courier, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :seller_memberships, dependent: :destroy
  has_many :sellers, through: :seller_memberships

  ROLES = %w[customer seller courier admin].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  def roles
    role_assignments.pluck(:role).map(&:to_sym)
  end

  def has_role?(role)
    roles.include?(role.to_sym)
  end

  def admin?
    has_role?(:admin)
  end

  def seller
    sellers.first
  end

  def seller_ids
    seller_id = seller_memberships.pick(:seller_id)
    seller_id ? [ seller_id ] : []
  end

  def member_of_seller?(seller_id)
    seller_memberships.exists?(seller_id: seller_id)
  end

  def disable!
    update!(active: false, disabled_at: Time.current)
    sessions.update_all(revoked_at: Time.current)
  end

  def enable!
    update!(active: true, disabled_at: nil)
  end

  def disabled?
    disabled_at.present? || !active?
  end

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
