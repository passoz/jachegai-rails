class Api::V1::BaseController < ApplicationController
  skip_forgery_protection

  # Error classes for auth/authz failures
  class Unauthorized < StandardError; end
  class Forbidden < StandardError; end
  class RateLimited < StandardError; end

  # Shared rate limiter for auth endpoints (5 attempts/min/IP).
  # Always resolves to a single instance on BaseController so subclasses
  # (AuthController, etc.) share the same store instead of each memoizing
  # their own @rate_limiter.
  def self.rate_limiter
    @rate_limiter ||= RateLimiter.new(
      store: Rails.env.test? ? RateLimiter::MemoryStore.new : RateLimiter::RailsCacheStore.new,
      limit: 5,
      window: 60
    )
  end

  def self.shared_rate_limiter
    Api::V1::BaseController.rate_limiter
  end

  rescue_from StandardError, with: :internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :invalid_input
  rescue_from DomainError, with: :domain_error
  rescue_from Api::V1::BaseController::Unauthorized, with: :unauthorized_error
  rescue_from Api::V1::BaseController::Forbidden, with: :forbidden_error
  rescue_from Api::V1::BaseController::RateLimited, with: :rate_limited_error

  before_action :authenticate!

  private

  # ----- Authentication -----

  def authenticate!
    token = bearer_token
    principal = token && SessionService.validate(token)

    if principal.nil?
      raise Unauthorized
    end

    Current.principal = principal
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header[/\ABearer\s+(.+)\z/i, 1]
  end

  # ----- Rate limiting -----

  def check_rate_limit!(*keys)
    limiter = self.class.shared_rate_limiter
    keys.each do |key|
      @rate_limit_status = limiter.status(key)
      unless limiter.allowed?(key)
        @rate_limit_status = limiter.status(key)
        Rails.logger.warn({ event: "rate_limited", key: key.gsub(/:[^:]+\z/, ":[filtered]"), request_id: Current.request_id }.to_json)
        raise RateLimited
      end
    end
    @rate_limit_status = limiter.status(keys.first)
  end

  def rate_limit_key(prefix, identifier: nil)
    normalized = identifier.to_s.strip.downcase
    suffix = normalized.present? ? normalized : request.remote_ip
    "#{prefix}:#{suffix}"
  end

  # ----- Strict JSON payload -----

  # Parses the raw request body with StrictJson (content-type, size, unknown
  # field enforcement). On failure it renders the error envelope and returns
  # nil; on success it sets @payload and returns the parsed hash.
  def parse_payload!(allowed_fields: [])
    raw = request.raw_post
    parsed =
      begin
        StrictJson.parse(
          raw,
          allowed_fields: allowed_fields,
          content_type: request.content_type,
          max_bytes: StrictJson::DEFAULT_MAX_BYTES
        )
      rescue StrictJson::Error => e
        render_error(
          code: e.code.to_s,
          message: I18n.t("errors.messages.#{e.code}", default: I18n.t("errors.messages.invalid_input")),
          status: e.http_status,
          context: { reason: e.code }
        )
        return false
      end

    @payload = parsed.deep_symbolize_keys
  end

  # ----- Input validation and pagination -----

  def require_payload_fields!(*fields)
    missing = fields.reject { |field| @payload.key?(field) && !@payload[field].nil? }
    return if missing.empty?

    raise DomainError.new(
      code: :invalid_input,
      http_status: :unprocessable_content,
      context: { fields: missing.index_with { [ I18n.t("errors.messages.blank") ] } }
    )
  end

  def require_integer_field!(field, minimum: nil)
    require_payload_fields!(field)
    value = @payload[field]
    valid = value.is_a?(Integer) && (minimum.nil? || value >= minimum)
    return value if valid

    invalid_payload_field!(field)
  end

  def require_string_field!(field, allow_nil: false)
    return if !@payload.key?(field) || (allow_nil && @payload[field].nil?)
    return @payload[field] if @payload[field].is_a?(String)

    invalid_payload_field!(field)
  end

  def require_boolean_field!(field)
    return unless @payload.key?(field)
    return @payload[field] if @payload[field] == true || @payload[field] == false

    invalid_payload_field!(field)
  end

  def require_string_array_field!(field)
    require_payload_fields!(field)
    value = @payload[field]
    return value if value.is_a?(Array) && value.all? { |element| element.is_a?(String) }

    invalid_payload_field!(field)
  end

  def invalid_payload_field!(field)
    raise DomainError.new(
      code: :invalid_input,
      http_status: :unprocessable_content,
      context: { fields: { field => [ I18n.t("errors.messages.invalid") ] } }
    )
  end

  def paginate(scope)
    ApiPagination.new(scope: scope, page: params[:page], per_page: params[:per_page])
  end

  # ----- Seller scoping -----

  # MVP invariant: a user can have at most one seller membership. The unique
  # database index on seller_memberships.user_id makes this lookup unambiguous.
  def current_seller
    return @current_seller if defined?(@current_seller)

    @current_seller = Current.principal&.seller
  end

  # Seller-scoped actions must have a seller profile; otherwise 404 so the
  # endpoint does not disclose whether a seller exists.
  def require_seller!
    current_seller || raise(ActiveRecord::RecordNotFound, "Seller profile not found")
  end

  def require_admin!
    raise Forbidden unless Current.principal&.admin?
  end

  # ----- Authorization -----

  # authorize!(record, action:) resolves the policy class from the record
  # and raises Forbidden unless the action is allowed.
  def authorize!(record = nil, action: nil)
    policy = policy_for(record)
    action ||= action_name.to_sym
    unless policy.public_send(:"#{action}?")
      raise Forbidden
    end
    policy
  end

  def policy_for(record)
    klass =
      if record.nil?
        "#{controller_name.classify}Policy".safe_constantize
      elsif record.is_a?(Class)
        "#{record.name}Policy".safe_constantize
      else
        "#{record.class.name}Policy".safe_constantize
      end

    # Prefer a policy in the controller's own namespace, e.g.
    # Api::V1::Admin::SellersController -> Admin::SellerPolicy. This prevents
    # an admin-only endpoint from silently falling back to the base policy.
    klass = namespaced_policy_name&.safe_constantize || klass
    klass ||= BasePolicy
    klass.new(Current.principal, record)
  end

  def namespaced_policy_name
    parts = self.class.name.delete_prefix("Api::V1::").delete_suffix("Controller")
    return nil if parts.blank?

    parts = parts.split("::")
    resource_policy = "#{parts.pop.singularize.camelize}Policy"
    (parts + [ resource_policy ]).join("::")
  end

  # ----- Envelope rendering -----

  def render_success(data:, meta: {}, status: :ok)
    render json: { ok: true, data: data, meta: meta }, status: status
  end

  def render_error(code:, message:, status: :bad_request, context: {}, headers: {})
    render json: {
      ok: false,
      error: { code: code, message: message, context: context }.compact
    }, status: status, headers: headers
  end

  def domain_error(exception)
    render_error(
      code: exception.code,
      message: exception.message,
      status: exception.http_status,
      context: exception.as_json[:context] || {}
    )
  end

  def not_found(exception)
    render_error(
      code: "not_found",
      message: I18n.t("errors.messages.not_found"),
      status: :not_found
    )
  end

  def invalid_input(exception)
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :bad_request
    )
  end

  def record_invalid(exception)
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :unprocessable_content,
      context: { fields: exception.record.errors.to_hash }
    )
  end

  def unauthorized_error(exception)
    render_error(
      code: "unauthorized",
      message: I18n.t("errors.messages.unauthorized"),
      status: :unauthorized
    )
  end

  def forbidden_error(exception)
    render_error(
      code: "forbidden",
      message: I18n.t("errors.messages.forbidden"),
      status: :forbidden
    )
  end

  def rate_limited_error(exception)
    headers = {}
    if @rate_limit_status
      headers["X-RateLimit-Limit"] = @rate_limit_status[:limit].to_s
      headers["X-RateLimit-Remaining"] = "0"
      headers["Retry-After"] = "60"
    end
    headers.each { |name, value| response.set_header(name, value) }
    render_error(
      code: "rate_limited",
      message: I18n.t("errors.messages.rate_limited"),
      status: :too_many_requests
    )
  end

  def payload_too_large_error(exception)
    render_error(
      code: "payload_too_large",
      message: I18n.t("errors.messages.payload_too_large", default: I18n.t("errors.messages.invalid_input")),
      status: :content_too_large
    )
  end

  def internal_error(exception)
    Rails.logger.error({ event: "internal_error", exception: exception.class.name, request_id: Current.request_id }.to_json)
    render_error(
      code: "internal_error",
      message: I18n.t("errors.messages.internal_error"),
      status: :internal_server_error
    )
  end
end
