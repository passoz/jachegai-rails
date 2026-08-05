require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user generates UUID v7 id" do
    user = User.new(email: "test@example.com", password: "password123", full_name: "Test User")
    user.save!
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}\z/, user.id)
  end

  test "user email is unique and normalized" do
    User.create!(email: "Test@Example.com", password: "password123", full_name: "Test")
    duplicate = User.new(email: " test@example.com ", password: "password123", full_name: "Test2")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "user password digest is stored, not plaintext" do
    user = User.create!(email: "test@example.com", password: "password123", full_name: "Test")
    assert_not_equal "password123", user.password_digest
    assert user.authenticate("password123")
    assert_not user.authenticate("wrong")
  end

  test "user password shorter than 8 fails" do
    user = User.new(email: "test@example.com", password: "short", full_name: "Test")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "public registration cannot create admin role" do
    user = User.new(email: "test@example.com", password: "password123", full_name: "Test")
    # Roles are derived from RoleAssignment; there is no settable roles= method exposed
    refute_respond_to user, :roles=
  end
end
