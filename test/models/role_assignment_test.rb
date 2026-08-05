require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "roles@example.com", password: "password123", full_name: "Role User")
  end

  test "assigns valid role" do
    assignment = RoleAssignment.create!(user: @user, role: "customer")
    assert assignment.persisted?
    assert_equal :customer, @user.roles.first
  end

  test "rejects invalid role" do
    assignment = RoleAssignment.new(user: @user, role: "superuser")
    assert_not assignment.valid?
    assert assignment.errors[:role].any?
  end

  test "prevents duplicate role per user" do
    RoleAssignment.create!(user: @user, role: "customer")
    duplicate = RoleAssignment.new(user: @user, role: "customer")
    assert_not duplicate.valid?
    assert duplicate.errors[:role].any?
  end

  test "user can have multiple roles" do
    RoleAssignment.create!(user: @user, role: "customer")
    RoleAssignment.create!(user: @user, role: "seller")
    assert_equal %i[customer seller], @user.roles.sort_by(&:to_s)
  end

  test "admin role must be explicitly assigned, not via public registration" do
    refute @user.admin?
    RoleAssignment.create!(user: @user, role: "admin")
    assert @user.admin?
  end
end
