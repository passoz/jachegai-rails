require "test_helper"

class CourierLocationCleanupJobTest < ActiveJob::TestCase
  setup do
    @courier_user = User.create!(email: "courier.clean@example.com", password: "password123", full_name: "Courier Clean")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511977778888", document_number: "77788899900",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available",
      location_consent_given_at: Time.current
    )

    # Location 1: 25 hours old (should be cleaned up)
    @old_location = CourierLocation.create!(
      courier: @courier, latitude: -23.5501, longitude: -46.6331,
      accuracy_meters: 10.0, recorded_at: 25.hours.ago
    )

    # Location 2: 1 hour old (should remain)
    @recent_location = CourierLocation.create!(
      courier: @courier, latitude: -23.5505, longitude: -46.6333,
      accuracy_meters: 5.0, recorded_at: 1.hour.ago
    )
  end

  test "removes location records older than 24 hours while keeping recent ones" do
    CourierLocationCleanupJob.perform_now

    refute CourierLocation.exists?(@old_location.id)
    assert CourierLocation.exists?(@recent_location.id)
  end

  test "job execution is idempotent" do
    CourierLocationCleanupJob.perform_now
    assert_nothing_raised do
      CourierLocationCleanupJob.perform_now
    end
    assert CourierLocation.exists?(@recent_location.id)
  end
end
