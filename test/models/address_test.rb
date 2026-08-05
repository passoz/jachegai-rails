require "test_helper"

class AddressTest < ActiveSupport::TestCase
  setup do
    @user1 = User.create!(email: "user1@example.com", password: "password123", full_name: "User One")
    @user1.role_assignments.create!(role: "customer")
    @user2 = User.create!(email: "user2@example.com", password: "password123", full_name: "User Two")
    @user2.role_assignments.create!(role: "customer")
  end

  test "valid address requires customer, name, line1, city, state, zip, and country" do
    address = Address.new(
      customer: @user1.customer,
      name: "Home",
      line1: "Rua A, 123",
      city: "São Paulo",
      state: "SP",
      zip: "01000-000",
      country: "BR"
    )
    assert address.valid?

    # Test presence validations
    %i[name line1 city state zip country].each do |field|
      bad_address = address.dup
      bad_address.send("#{field}=", nil)
      refute bad_address.valid?, "Address should be invalid without #{field}"
      assert bad_address.errors[field].any?
    end
  end

  test "enforces single default address per customer" do
    addr1 = Address.create!(
      customer: @user1.customer, name: "Home", line1: "Rua A, 123",
      city: "São Paulo", state: "SP", zip: "01000-000",
      is_default: true
    )
    assert addr1.is_default?

    addr2 = Address.create!(
      customer: @user1.customer, name: "Work", line1: "Rua B, 456",
      city: "São Paulo", state: "SP", zip: "02000-000",
      is_default: false
    )
    refute addr2.is_default?

    # Now make addr2 the default
    addr2.update!(is_default: true)
    assert addr2.reload.is_default?
    refute addr1.reload.is_default?, "addr1 should not be default anymore"
  end

  test "supports multiple customers with their own default addresses" do
    addr1 = Address.create!(
      customer: @user1.customer, name: "Home", line1: "Rua A, 123",
      city: "São Paulo", state: "SP", zip: "01000-000",
      is_default: true
    )
    addr2 = Address.create!(
      customer: @user2.customer, name: "Home", line1: "Rua X, 789",
      city: "São Paulo", state: "SP", zip: "03000-000",
      is_default: true
    )

    assert addr1.reload.is_default?
    assert addr2.reload.is_default?
  end

  test "maintains unique default constraint at database index level" do
    addr1 = Address.create!(
      customer: @user1.customer, name: "Home", line1: "Rua A, 123",
      city: "São Paulo", state: "SP", zip: "01000-000",
      is_default: true
    )

    # Bypass ActiveRecord callbacks to simulate concurrent race condition
    assert_raises ActiveRecord::RecordNotUnique do
      Address.insert_all!(
        [ {
          id: ApplicationId.generate,
          customer_id: @user1.customer.id,
          name: "Work",
          line1: "Rua B, 456",
          city: "São Paulo",
          state: "SP",
          zip: "02000-000",
          country: "BR",
          is_default: true,
          created_at: Time.current,
          updated_at: Time.current
        } ]
      )
    end
  end
end
