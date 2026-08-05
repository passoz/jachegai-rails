require "test_helper"

class DomainErrorTest < ActiveSupport::TestCase
  test "DomainError has code and http_status" do
    err = DomainError.new(code: :not_found)
    assert_equal "not_found", err.code
    assert_equal :not_found, err.http_status
  end

  test "DomainError uses I18n message by default" do
    err = DomainError.new(code: :not_found)
    assert_equal I18n.t("errors.messages.not_found"), err.message
  end

  test "DomainError allows custom message" do
    err = DomainError.new(code: :forbidden, message: "Custom message")
    assert_equal "Custom message", err.message
    assert_equal :forbidden, err.http_status
  end

  test "DomainError exposes context in as_json" do
    err = DomainError.new(code: :insufficient_inventory, context: { product_id: "abc" })
    json = err.as_json
    assert_equal "insufficient_inventory", json[:code]
    assert_equal({ product_id: "abc" }, json[:context])
  end

  test "DomainError maps all documented statuses" do
    expected = {
      "invalid_input" => :unprocessable_content,
      "not_found" => :not_found,
      "unauthorized" => :unauthorized,
      "forbidden" => :forbidden,
      "internal_error" => :internal_server_error,
      "idempotency_conflict" => :conflict,
      "insufficient_inventory" => :conflict,
      "expired" => :gone,
      "already_exists" => :conflict
    }
    expected.each do |code, status|
      err = DomainError.new(code: code)
      assert_equal status, err.http_status, "code #{code} should map to #{status}"
    end
  end
end
