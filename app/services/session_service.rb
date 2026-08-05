# SessionService handles authentication flows: login, logout, and token validation.
class SessionService
  class AuthenticationError < StandardError; end

  def self.login(email:, password:, ip: nil, user_agent: nil)
    user = User.find_by(email: email.to_s.strip.downcase)
    # Undifferentiated error to avoid account enumeration
    raise AuthenticationError, "invalid_credentials" unless user&.authenticate(password)
    raise AuthenticationError, "disabled" unless user.active?

    token = Session.issue_for(user, ip: ip, user_agent: user_agent, revoke_existing: true)
    { user: user, token: token }
  end

  def self.logout(token)
    session = Session.find_by_token(token)
    session&.revoke!
    true
  end

  def self.validate(token)
    session = Session.find_by_token(token)
    return nil unless session
    return nil unless session.user.active?

    session.touch_seen!
    Principal.new(user: session.user, session: session)
  end
end
