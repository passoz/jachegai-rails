require "test_helper"

class CustomerPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "customer-policy@example.com", password: "password123", full_name: "Owner")
    @owner.role_assignments.create!(role: "customer")
    @other = User.create!(email: "customer-policy-other@example.com", password: "password123", full_name: "Other")
    @other.role_assignments.create!(role: "customer")
  end

  test "allows only the customer profile owner" do
    policy = CustomerPolicy.new(Principal.new(user: @owner), @owner.customer)
    assert policy.show?
    assert policy.update?

    foreign_policy = CustomerPolicy.new(Principal.new(user: @other), @owner.customer)
    refute foreign_policy.show?
    refute foreign_policy.update?
  end

  test "denies a principal without customer role" do
    seller = User.create!(email: "customer-policy-seller@example.com", password: "password123", full_name: "Seller")
    seller.role_assignments.create!(role: "seller")

    policy = CustomerPolicy.new(Principal.new(user: seller), @owner.customer)
    refute policy.show?
    refute policy.update?
  end
end
