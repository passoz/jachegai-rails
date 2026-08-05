require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "session@example.com", password: "password123", full_name: "Session User")
  end

  test "session stores token digest, never plaintext" do
    token = Session.issue_for(@user, ip: "127.0.0.1", user_agent: "test")
    # The token is returned but not stored
    assert token.is_a?(String)
    session = Session.last
    assert_not_equal token, session.token_digest
    assert_equal Digest::SHA256.hexdigest(token), session.token_digest
  end

  test "session expires in 7 days" do
    Session.issue_for(@user)
    session = Session.last
    assert_in_delta Time.current + 7.days, session.expires_at, 1.minute
  end

  test "missing token does not raise" do
    assert_nil Session.find_by_token(nil)
    assert_nil Session.find_by_token("")
  end

  test "session is found by token" do
    token = Session.issue_for(@user)
    found = Session.find_by_token(token)
    assert_equal @user.id, found.user_id
  end

  test "session can be revoked" do
    token = Session.issue_for(@user)
    session = Session.find_by_token(token)
    session.revoke!
    assert session.revoked?
    assert_nil Session.find_by_token(token)
  end

  test "expired session is rejected" do
    token = Session.issue_for(@user)
    session = Session.find_by_token(token)
    session.update!(expires_at: 1.minute.ago)
    assert session.expired?
    assert_nil Session.find_by_token(token)
  end

  test "disabled user session is rejected" do
    token = Session.issue_for(@user)
    session = Session.find_by_token(token)
    assert session.present?
    @user.disable!
    # After disabling, the session is revoked and no longer findable via active scope
    assert session.reload.revoked?
    assert_nil Session.find_by_token(token)
  end
end
