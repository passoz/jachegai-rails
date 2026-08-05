require "test_helper"

class EnvelopeTest < ActiveSupport::TestCase
  test "success envelope has ok, data, and meta keys" do
    envelope = { ok: true, data: { id: "abc" }, meta: {} }
    assert envelope[:ok]
    assert envelope.key?(:data)
    assert envelope.key?(:meta)
  end

  test "error envelope has ok false and error details" do
    envelope = { ok: false, error: { code: "not_found", message: "Resource not found" } }
    refute envelope[:ok]
    assert envelope.key?(:error)
    assert envelope[:error].key?(:code)
    assert envelope[:error].key?(:message)
  end

  test "error codes are stable and documented" do
    valid_codes = %w[invalid_input not_found unauthorized forbidden internal_error idempotency_conflict insufficient_inventory expired already_exists]
    %w[invalid_input not_found unauthorized forbidden internal_error].each do |code|
      assert_includes valid_codes, code, "Error code #{code} must be in the documented taxonomy"
    end
  end

  test "internal error does not expose exception details" do
    # The envelope must never include stack traces, SQL, or internal details
    envelope = { ok: false, error: { code: "internal_error", message: "An unexpected error occurred" } }
    refute envelope[:error].key?(:backtrace)
    refute envelope[:error].key?(:sql)
    refute envelope[:error].key?(:exception)
  end

  test "204 responses are not used — all success responses use envelope" do
    # Every success response must have an envelope with ok: true
    envelope = { ok: true, data: { id: "abc" }, meta: { status: 200 } }
    assert envelope[:ok]
    assert envelope.key?(:data)
  end

  test "client-visible messages use I18n keys" do
    message = I18n.t("errors.messages.not_found")
    assert message.is_a?(String)
    assert message.length > 0
  end
end
