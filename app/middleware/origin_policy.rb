# OriginPolicy protects state-changing API requests from CSRF attacks.
# - Requests WITHOUT an Origin header are allowed (native/mobile API clients).
# - Requests WITH an Origin header must match an allowed host.
# - Non-state-changing requests (GET/HEAD/OPTIONS) are not checked.
class OriginPolicy
  DEFAULT_ALLOWED_HOSTS = [ "localhost", "127.0.0.1", "0.0.0.0" ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if state_changing?(request) && request.origin.present? && !allowed_origin?(request.origin)
      return forbidden(request)
    end

    @app.call(env)
  end

  private

  def state_changing?(request)
    !%w[GET HEAD OPTIONS].include?(request.request_method)
  end

  def allowed_origin?(origin)
    parsed = URI.parse(origin)
    return false unless %w[http https].include?(parsed.scheme)

    allowed_origins = Rails.application.config.x.jachegai[:allowed_origins]
    allowed_origins.any? do |allowed|
      normalized = allowed.to_s.strip
      if normalized.include?("://")
        normalized.casecmp?(origin)
      else
        parsed.host == normalized && parsed.port == default_port(parsed.scheme)
      end
    end
  rescue URI::InvalidURIError
    false
  end

  def default_port(scheme)
    scheme == "https" ? 443 : 80
  end

  def forbidden(request)
    body = {
      ok: false,
      error: {
        code: "forbidden",
        message: I18n.t("errors.messages.forbidden")
      }
    }.to_json

    [ 403, { "Content-Type" => "application/json" }, [ body ] ]
  end
end
