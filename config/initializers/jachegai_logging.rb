# Structured logging configuration for JaChegai.
# - LOG_LEVEL: debug (dev), info (prod)
# - LOG_FORMAT: text (dev), json (prod)
Rails.application.configure do
  config.log_level = Rails.application.config.x.jachegai[:log_level].to_sym

  if Rails.application.config.x.jachegai[:log_format] == "json"
    config.log_formatter = JachegaiJsonFormatter.new
  end

  # Filter sensitive parameters from logs
  config.filter_parameters += %i[
    password
    password_confirmation
    token
    refresh_token
    session
    secret
    authorization
    cookie
    cvv
    card_number
  ]
end
