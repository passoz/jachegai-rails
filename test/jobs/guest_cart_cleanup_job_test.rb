require "test_helper"

class GuestCartCleanupJobTest < ActiveJob::TestCase
  setup do
    @seller = Seller.create!(name: "Test Store", moderation_state: "approved")

    # Active cart
    _token1, digest1 = GuestCart.generate_token
    @active_cart = GuestCart.create!(token_digest: digest1, seller: @seller, expires_at: 1.day.from_now)

    # Expired cart 1
    _token2, digest2 = GuestCart.generate_token
    @expired_cart1 = GuestCart.create!(token_digest: digest2, seller: @seller, expires_at: 1.minute.ago)

    # Expired cart 2
    _token3, digest3 = GuestCart.generate_token
    @expired_cart2 = GuestCart.create!(token_digest: digest3, seller: @seller, expires_at: 2.days.ago)
  end

  test "recurring schedule enqueues the cleanup job in production" do
    schedule = YAML.safe_load_file(Rails.root.join("config", "recurring.yml"))
    cleanup = schedule.fetch("production").fetch("guest_cart_cleanup")

    assert_equal "GuestCartCleanupJob", cleanup.fetch("class")
    assert cleanup.fetch("schedule").present?
  end

  test "job removes only expired carts idempotently" do
    assert_difference "GuestCart.count", -2 do
      GuestCartCleanupJob.perform_now
    end

    assert GuestCart.exists?(@active_cart.id)
    refute GuestCart.exists?(@expired_cart1.id)
    refute GuestCart.exists?(@expired_cart2.id)

    # Idempotent re-execution
    assert_no_difference "GuestCart.count" do
      GuestCartCleanupJob.perform_now
    end
  end
end
