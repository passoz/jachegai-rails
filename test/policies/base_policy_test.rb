require "test_helper"

class BasePolicyTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "policy@example.com", password: "password123", full_name: "Policy User")
    @principal = Principal.new(user: @user)
  end

  test "denies unauthenticated access by default" do
    policy = BasePolicy.new(nil)
    refute policy.index?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
  end

  test "allows authenticated read access by default" do
    policy = BasePolicy.new(@principal)
    assert policy.index?
    assert policy.show?
  end

  test "denies writes by default so missing policies fail closed" do
    policy = BasePolicy.new(@principal)
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
  end

  test "admin shortcut" do
    refute BasePolicy.new(@principal).admin?
    RoleAssignment.create!(user: @user, role: "admin")
    assert BasePolicy.new(Principal.new(user: @user)).admin?
  end
end
