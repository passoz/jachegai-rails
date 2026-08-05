class GuestCart < ApplicationRecord
  before_create :generate_server_id

  belongs_to :seller, optional: true
  has_many :guest_cart_items, dependent: :destroy
  has_many :products, through: :guest_cart_items

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :set_default_expiry, on: :create

  def self.generate_token
    token = SecureRandom.urlsafe_base64(32)
    digest = Digest::SHA256.hexdigest(token)
    [ token, digest ]
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def set_default_expiry
    self.expires_at ||= 7.days.from_now
  end

  def generate_server_id
    self.id ||= ApplicationId.generate
  end
end
