require "test_helper"

class PrincipalTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "principal@example.com", password: "password123", full_name: "Principal User")
    RoleAssignment.create!(user: @user, role: "seller")
  end

  test "exposes user attributes" do
    principal = Principal.new(user: @user)
    assert_equal @user.id, principal.id
    assert principal.active?
  end

  test "exposes roles" do
    principal = Principal.new(user: @user)
    assert_includes principal.roles, :seller
    assert principal.has_role?(:seller)
    refute principal.has_role?(:admin)
    refute principal.admin?
    refute principal.system?
  end

  test "admin role detection" do
    RoleAssignment.create!(user: @user, role: "admin")
    principal = Principal.new(user: @user)
    assert principal.admin?
  end
end
