require "test_helper"

class SessionServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "login@example.com", password: "password123", full_name: "Login User")
    RoleAssignment.create!(user: @user, role: "customer")
  end

  test "login returns user and token" do
    result = SessionService.login(email: "login@example.com", password: "password123", ip: "127.0.0.1")
    assert_equal @user.id, result[:user].id
    assert result[:token].is_a?(String)
    assert result[:token].length >= 32
  end

  test "a new login revokes the previous session" do
    first = SessionService.login(email: @user.email, password: "password123")[:token]
    second = SessionService.login(email: @user.email, password: "password123")[:token]
    assert_nil SessionService.validate(first)
    assert SessionService.validate(second).present?
  end

  test "login with wrong password raises" do
    assert_raises(SessionService::AuthenticationError) do
      SessionService.login(email: "login@example.com", password: "wrongpassword")
    end
  end

  test "login with unknown email raises same error" do
    error = assert_raises(SessionService::AuthenticationError) do
      SessionService.login(email: "nobody@example.com", password: "password123")
    end
    assert_equal "invalid_credentials", error.message
  end

  test "login is case-insensitive and trims email" do
    result = SessionService.login(email: "  LOGIN@example.com  ", password: "password123")
    assert_equal @user.id, result[:user].id
  end

  test "login for disabled user raises" do
    @user.disable!
    assert_raises(SessionService::AuthenticationError) do
      SessionService.login(email: "login@example.com", password: "password123")
    end
  end

  test "validate returns principal for valid token" do
    token = Session.issue_for(@user)
    principal = SessionService.validate(token)
    assert_equal @user.id, principal.id
    assert principal.has_role?(:customer)
  end

  test "validate returns nil for revoked token" do
    token = Session.issue_for(@user)
    SessionService.logout(token)
    assert_nil SessionService.validate(token)
  end

  test "logout revokes session" do
    token = Session.issue_for(@user)
    SessionService.logout(token)
    session = Session.find_by_token(token)
    assert_nil session
  end
end
