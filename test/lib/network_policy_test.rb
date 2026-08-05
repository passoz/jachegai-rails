require "test_helper"

class NetworkPolicyTest < ActiveSupport::TestCase
  test "provides explicit default timeout" do
    assert_equal 5, NetworkPolicy.timeout_seconds
    assert_equal 10, NetworkPolicy.timeout_seconds(configured: 10)
  end

  test "bounded retries stop after max attempts" do
    attempts = 0
    error = assert_raises(RuntimeError) do
      NetworkPolicy.with_bounded_retries(max_retries: 3) do
        attempts += 1
        raise "flaky"
      end
    end

    assert_equal "flaky", error.message
    assert_equal 3, attempts, "must stop after max_retries"
  end

  test "retry delay is bounded by MAX_BACKOFF_SECONDS" do
    assert_operator NetworkPolicy.retry_delay(1), :<=, NetworkPolicy::MAX_BACKOFF_SECONDS
    assert_operator NetworkPolicy.retry_delay(10), :<=, NetworkPolicy::MAX_BACKOFF_SECONDS
  end
end
