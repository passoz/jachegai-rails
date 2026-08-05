class Seller < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id
  before_validation :set_slug, on: :create

  has_many :memberships, class_name: "SellerMembership", dependent: :destroy
  has_many :users, through: :memberships
  has_one :settings, class_name: "SellerSettings", dependent: :destroy
  has_many :categories, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :inventory_items, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :uploads, as: :owner, dependent: :restrict_with_error

  MODERATION_STATES = %w[pending_review approved suspended rejected].freeze

  validates :name, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :moderation_state, inclusion: { in: MODERATION_STATES }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :by_state, ->(state) { where(moderation_state: state) }
  scope :approved, -> { where(moderation_state: "approved") }

  def self.page_for_api(page = nil, per_page = nil)
    normalized_page, normalized_per_page = ApiPagination.values(page, per_page)
    offset((normalized_page - 1) * normalized_per_page).limit(normalized_per_page)
  end

  def pending_review?
    moderation_state == "pending_review"
  end

  def approved?
    moderation_state == "approved"
  end

  private

  def set_id
    self.id ||= ApplicationId.generate
  end

  def set_slug
    return if slug.present?

    base = name.to_s.parameterize
    base = "seller" if base.blank?
    candidate = base
    suffix = 2
    while Seller.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end
end
