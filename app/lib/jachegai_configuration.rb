class JachegaiConfiguration
  VALID_LOG_LEVELS = %w[debug info warn error].freeze
  VALID_LOG_FORMATS = %w[text json].freeze

  def self.validate!(settings, production: Rails.env.production?)
    port = Integer(settings.fetch(:port))
    raise ArgumentError, "PORT must be between 1 and 65535" unless port.between?(1, 65_535)
    raise ArgumentError, "LOG_LEVEL is invalid" unless VALID_LOG_LEVELS.include?(settings.fetch(:log_level).to_s)
    raise ArgumentError, "LOG_FORMAT is invalid" unless VALID_LOG_FORMATS.include?(settings.fetch(:log_format).to_s)
    raise ArgumentError, "DATABASE_PATH must not be blank" if settings[:database_path].to_s.strip.empty?

    origins = settings.fetch(:allowed_origins)
    raise ArgumentError, "ALLOWED_ORIGINS must not be empty" if origins.empty?
    origins.each { |origin| validate_origin!(origin) }

    secret = settings[:jwt_secret].to_s
    if production && (secret.blank? || secret == "dev-secret-change-in-production" || secret.length < 32)
      raise ArgumentError, "JWT_SECRET must be a strong production secret"
    end

    settings
  end

  def self.validate_origin!(origin)
    uri = URI.parse(origin.to_s)
    valid = %w[http https].include?(uri.scheme) && uri.host.present? && uri.userinfo.nil?
    raise ArgumentError, "ALLOWED_ORIGINS contains an invalid origin" unless valid
  rescue URI::InvalidURIError
    raise ArgumentError, "ALLOWED_ORIGINS contains an invalid origin"
  end

  private_class_method :validate_origin!
end
