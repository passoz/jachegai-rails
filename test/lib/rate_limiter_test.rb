require "test_helper"

class RateLimiterTest < ActiveSupport::TestCase
  setup do
    @store = RateLimiter::MemoryStore.new
    @limiter = RateLimiter.new(store: @store, limit: 5, window: 60)
  end

  test "allows requests under the limit" do
    5.times do
      assert @limiter.allowed?("login:1.2.3.4"), "request should be allowed"
    end
  end

  test "blocks requests over the limit" do
    5.times { @limiter.allowed?("login:1.2.3.4") }
    assert_not @limiter.allowed?("login:1.2.3.4")
    assert_not @limiter.allowed?("login:1.2.3.4")
  end

  test "tracks per-key independently" do
    5.times { @limiter.allowed?("login:1.2.3.4") }
    assert @limiter.allowed?("login:5.6.7.8")
  end

  test "window expires and allows again" do
    limiter = RateLimiter.new(store: @store, limit: 2, window: 1)
    2.times { limiter.allowed?("login:x") }
    refute limiter.allowed?("login:x")
    sleep 1.1
    assert limiter.allowed?("login:x")
  end

  test "returns remaining and reset info" do
    status = @limiter.status("login:1.2.3.4")
    assert_equal 5, status[:remaining]
    assert status[:reset_at].present?
  end
end
