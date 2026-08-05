require "test_helper"

class StrictJsonTest < ActiveSupport::TestCase
  JSON_TYPE = "application/json"

  test "parses valid JSON hash" do
    result = StrictJson.parse('{"name":"test"}', allowed_fields: %i[name], content_type: JSON_TYPE)
    assert_equal({ "name" => "test" }, result)
  end

  test "returns empty hash for blank input" do
    assert_equal({}, StrictJson.parse(""))
    assert_equal({}, StrictJson.parse(nil))
  end

  test "rejects malformed JSON" do
    error = assert_raises(StrictJson::Error) do
      StrictJson.parse("{invalid", allowed_fields: %i[name], content_type: JSON_TYPE)
    end
    assert_equal :invalid_json, error.code
    assert_equal :bad_request, error.http_status
  end

  test "rejects non-object JSON" do
    error = assert_raises(StrictJson::Error) do
      StrictJson.parse("[1,2,3]", allowed_fields: %i[name], content_type: JSON_TYPE)
    end
    assert_equal :invalid_json, error.code
  end

  test "rejects unknown fields" do
    error = assert_raises(StrictJson::Error) do
      StrictJson.parse('{"name":"test","evil":"x"}', allowed_fields: %i[name], content_type: JSON_TYPE)
    end
    assert_equal :unknown_fields, error.code
    assert_equal :unprocessable_content, error.http_status
  end

  test "accepts all allowed fields" do
    result = StrictJson.parse('{"name":"a","other":"b"}', allowed_fields: %i[name other], content_type: JSON_TYPE)
    assert_equal({ "name" => "a", "other" => "b" }, result)
  end

  test "rejects a non-JSON content type" do
    error = assert_raises(StrictJson::Error) do
      StrictJson.parse('{"name":"test"}', allowed_fields: %i[name], content_type: "text/plain")
    end
    assert_equal :invalid_content_type, error.code
    assert_equal :bad_request, error.http_status
  end

  test "rejects a missing content type" do
    assert_raises(StrictJson::Error) do
      StrictJson.parse('{"name":"test"}', allowed_fields: %i[name])
    end
  end

  test "rejects a body over the configured limit" do
    error = assert_raises(StrictJson::Error) do
      StrictJson.parse('{"name":"test"}', allowed_fields: %i[name], content_type: JSON_TYPE, max_bytes: 5)
    end
    assert_equal :payload_too_large, error.code
    assert_equal :content_too_large, error.http_status
  end
end
