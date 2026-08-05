require "test_helper"

class CourierLocationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "courier.loc@example.com", password: "password123", full_name: "Courier Loc")
    @user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @user, phone: "+5511911112222", document_number: "11122233355",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available",
      location_consent_given_at: Time.current
    )
  end

  test "creates valid courier location" do
    location = CourierLocation.new(
      courier: @courier,
      latitude: -23.55052,
      longitude: -46.633308,
      accuracy_meters: 10.5,
      recorded_at: Time.current
    )

    assert location.save
    assert location.id.present?
  end

  test "validates coordinates range" do
    invalid_lat = CourierLocation.new(courier: @courier, latitude: 95.0, longitude: -46.0, recorded_at: Time.current)
    refute invalid_lat.valid?

    invalid_lng = CourierLocation.new(courier: @courier, latitude: -23.0, longitude: -185.0, recorded_at: Time.current)
    refute invalid_lng.valid?
  end
end
