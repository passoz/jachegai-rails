# Centralized domain error taxonomy for the JaChegai API.
# Every error code maps to a stable HTTP status and an I18n message.
class DomainError < StandardError
  attr_reader :code, :http_status

  def initialize(code:, message: nil, http_status: nil, context: nil, **details)
    @code = code.to_s
    @http_status = http_status || DEFAULT_STATUS.fetch(@code, :bad_request)
    @context = context || details
    super(message || I18n.t("errors.messages.#{@code}", default: "errors.messages.#{@code}"))
  end

  def as_json(*)
    {
      code: @code,
      message: message,
      context: @context
    }.compact
  end

  DEFAULT_STATUS = {
    "invalid_input" => :unprocessable_content,
    "not_found" => :not_found,
    "unauthorized" => :unauthorized,
    "forbidden" => :forbidden,
    "internal_error" => :internal_server_error,
    "internal_failure" => :internal_server_error,
    "idempotency_conflict" => :conflict,
    "insufficient_inventory" => :conflict,
    "expired" => :gone,
    "already_exists" => :conflict,
    "invalid_transition" => :conflict,
    "category_in_use" => :conflict,
    "product_in_use" => :conflict,
    "rate_limited" => :too_many_requests,
    "payload_too_large" => :content_too_large,
    "file_too_large" => :content_too_large,
    "unsupported_content_type" => :bad_request,
    "unsafe_filename" => :bad_request,
    "storage_integrity_error" => :unprocessable_content,
    "invalid_content_type" => :bad_request,
    "service_unavailable" => :service_unavailable,
    "external_dependency_unavailable" => :service_unavailable
  }.freeze
end
