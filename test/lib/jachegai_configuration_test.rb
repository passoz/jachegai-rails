require "test_helper"

class JachegaiConfigurationTest < ActiveSupport::TestCase
  def settings(overrides = {})
    {
      port: "3000",
      log_level: "info",
      log_format: "json",
      database_path: "storage/test.sqlite3",
      allowed_origins: [ "http://localhost:3000" ],
      jwt_secret: "a" * 32
    }.merge(overrides)
  end

  test "rejects invalid logging configuration" do
    assert_raises(ArgumentError) { JachegaiConfiguration.validate!(settings(log_level: "trace"), production: false) }
  end

  test "rejects invalid origin" do
    assert_raises(ArgumentError) { JachegaiConfiguration.validate!(settings(allowed_origins: [ "evil" ]), production: false) }
  end

  test "requires a strong secret in production" do
    assert_raises(ArgumentError) { JachegaiConfiguration.validate!(settings(jwt_secret: "short"), production: true) }
  end

  test "accepts valid settings" do
    assert_equal settings, JachegaiConfiguration.validate!(settings, production: true)
  end
end
