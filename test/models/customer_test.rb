require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
  end

  test "customer role creates one distinct UUIDv7 buyer profile" do
    assert_difference -> { Customer.count }, 1 do
      @user.role_assignments.create!(role: "customer")
    end

    customer = @user.reload.customer
    assert_equal "Buyer", customer.full_name
    refute_equal @user.id, customer.id
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}\z/, customer.id)
  end

  test "database enforces one buyer profile per user" do
    @user.role_assignments.create!(role: "customer")

    assert_raises ActiveRecord::RecordNotUnique do
      Customer.insert_all!([ {
        id: ApplicationId.generate,
        user_id: @user.id,
        full_name: "Duplicate",
        created_at: Time.current,
        updated_at: Time.current
      } ])
    end
  end
end
