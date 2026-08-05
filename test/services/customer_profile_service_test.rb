require "test_helper"

class CustomerProfileServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "profile-service@example.com", password: "password123", full_name: "Original")
    @user.role_assignments.create!(role: "customer")
  end

  test "updates identity and buyer profile atomically" do
    customer = CustomerProfileService.update(
      customer: @user.customer,
      params: { email: "updated@example.com", full_name: "Updated", phone: "+55 11 99999-0000" }
    )

    assert_equal "updated@example.com", @user.reload.email
    assert_equal "Updated", @user.full_name
    assert_equal "Updated", customer.full_name
    assert_equal "+55 11 99999-0000", customer.phone
  end

  test "rolls back buyer profile when identity update fails" do
    taken = User.create!(email: "taken-service@example.com", password: "password123", full_name: "Taken")

    assert_raises ActiveRecord::RecordInvalid do
      CustomerProfileService.update(
        customer: @user.customer,
        params: { email: taken.email, full_name: "Must Roll Back", phone: "+55 11 90000-0000" }
      )
    end

    assert_equal "Original", @user.reload.full_name
    assert_equal "Original", @user.customer.reload.full_name
    assert_nil @user.customer.phone
  end
end
