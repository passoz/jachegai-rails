require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Custom middleware must be loaded before the middleware stack is built
require_relative "../app/middleware/request_context"
require_relative "../app/middleware/origin_policy"
require_relative "../app/lib/jachegai_configuration"
require_relative "../app/lib/strict_json"
require_relative "../app/middleware/request_body_limit"
require_relative "../app/middleware/request_logger"
require_relative "../app/lib/jachegai_json_formatter"

module JachegaiRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Autoload custom middleware directory
    config.autoload_paths << Rails.root.join("app/middleware")

    # Request correlation middleware
    config.middleware.insert_after ActionDispatch::RequestId, RequestContext
    config.middleware.insert_after RequestContext, RequestBodyLimit
    config.middleware.insert_after RequestBodyLimit, RequestLogger

    # CSRF/origin protection for state-changing requests
    config.middleware.insert_before Rack::Head, OriginPolicy

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    config.i18n.default_locale = :"pt-BR"
    config.i18n.available_locales = [ :"pt-BR", :en ]

    # Jachegai configuration
    config.x.jachegai = {
      jwt_secret: ENV.fetch("JWT_SECRET", "dev-secret-change-in-production"),
      log_level: ENV.fetch("LOG_LEVEL", ENV["RAILS_ENV"] == "production" ? "info" : "debug"),
      log_format: ENV.fetch("LOG_FORMAT", ENV["RAILS_ENV"] == "production" ? "json" : "text"),
      port: ENV.fetch("PORT", "3000"),
      database_path: ENV.fetch(
        "DATABASE_PATH",
        Rails.env.production? ? "storage/production.sqlite3" : "storage/development.sqlite3"
      ),
      allowed_origins: ENV.fetch(
        "ALLOWED_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:3000,http://0.0.0.0:3000"
      ).split(",").map(&:strip)
    }

    JachegaiConfiguration.validate!(config.x.jachegai, production: ENV["RAILS_ENV"] == "production")
  end
end
