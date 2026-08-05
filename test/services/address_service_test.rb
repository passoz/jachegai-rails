require "test_helper"

class AddressServiceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "address-service@example.com", password: "password123", full_name: "Customer")
    user.role_assignments.create!(role: "customer")
    @customer = user.customer
  end

  test "creates the first address as default" do
    address = AddressService.create(customer: @customer, params: address_params(name: "Home"))

    assert address.is_default?
    assert_equal 1, @customer.addresses.where(is_default: true).count
  end

  test "selecting a default atomically clears the previous default" do
    original = AddressService.create(customer: @customer, params: address_params(name: "Home"))
    replacement = AddressService.create(customer: @customer, params: address_params(name: "Work", line1: "Rua B"))

    AddressService.make_default(address: replacement)

    assert replacement.reload.is_default?
    refute original.reload.is_default?
  end

  test "updating a default to false deterministically promotes another address" do
    original = AddressService.create(customer: @customer, params: address_params(name: "Home"))
    replacement = AddressService.create(customer: @customer, params: address_params(name: "Work", line1: "Rua B"))

    AddressService.update(address: original, params: { name: "Renamed", is_default: false })

    assert_equal "Renamed", original.reload.name
    refute original.is_default?
    assert replacement.reload.is_default?
  end

  test "deleting the default promotes the newest remaining address" do
    default = AddressService.create(customer: @customer, params: address_params(name: "Home"))
    older = AddressService.create(customer: @customer, params: address_params(name: "Older", line1: "Rua B"))
    newest = AddressService.create(customer: @customer, params: address_params(name: "Newest", line1: "Rua C"))

    AddressService.destroy(address: default)

    assert newest.reload.is_default?
    refute older.reload.is_default?
  end

  private

  def address_params(name:, line1: "Rua A")
    { name: name, line1: line1, city: "São Paulo", state: "SP", zip: "01000-000", country: "BR" }
  end
end
