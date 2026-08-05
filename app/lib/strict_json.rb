# Strict JSON parsing for API inputs.
# Rejects malformed JSON, non-object bodies, and unknown fields.
class StrictJson
  DEFAULT_MAX_BYTES = 256.kilobytes

  class Error < StandardError
    attr_reader :code, :http_status

    def initialize(code:, http_status: :bad_request)
      @code = code
      @http_status = http_status
      super(code.to_s)
    end
  end

  def self.parse(raw, allowed_fields: [], content_type: nil, max_bytes: DEFAULT_MAX_BYTES)
    if raw.present? && (content_type.blank? || !content_type.to_s.split(";").first.casecmp?("application/json"))
      raise Error.new(code: :invalid_content_type)
    end

    return {} if raw.blank?

    if raw.bytesize > max_bytes
      raise Error.new(code: :payload_too_large, http_status: :content_too_large)
    end

    parsed = JSON.parse(raw)
    raise Error.new(code: :invalid_json) unless parsed.is_a?(Hash)

    if allowed_fields.any?
      unknown = parsed.keys.map(&:to_s) - allowed_fields.map(&:to_s)
      unless unknown.empty?
        raise Error.new(code: :unknown_fields, http_status: :unprocessable_content)
      end
    end

    parsed
  rescue JSON::ParserError
    raise Error.new(code: :invalid_json)
  end
end
