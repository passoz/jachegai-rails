class Session < ApplicationRecord
  self.primary_key = "id"

  before_create :set_id

  belongs_to :user

  TOKEN_TTL = 7.days

  validates :token_digest, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for(user, ip: nil, user_agent: nil, revoke_existing: false)
    transaction do
      where(user: user, revoked_at: nil).update_all(revoked_at: Time.current) if revoke_existing
      token = SecureRandom.urlsafe_base64(48)
      create!(
        user: user,
        token_digest: Digest::SHA256.hexdigest(token),
        expires_at: Time.current + TOKEN_TTL,
        ip_address: ip,
        user_agent: user_agent
      )
      token
    end
  end

  def self.find_by_token(token)
    return nil if token.blank?

    active.find_by(token_digest: Digest::SHA256.hexdigest(token))
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def touch_seen!
    update!(last_seen_at: Time.current)
  end

  private

  def set_id
    self.id ||= ApplicationId.generate
  end
end
