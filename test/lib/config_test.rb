require "test_helper"

class ConfigTest < ActiveSupport::TestCase
  def jachegai_config
    Rails.application.config.x.jachegai
  end

  test "JachegaiRails config exists" do
    assert_not_nil Rails.application.config.x
    assert_not_nil jachegai_config
  end

  test "config has mandatory keys" do
    assert jachegai_config.key?(:jwt_secret), "jwt_secret must be configured"
    assert jachegai_config.key?(:log_level), "log_level must be configured"
    assert jachegai_config.key?(:log_format), "log_format must be configured"
  end

  test "database path configuration is used by the active environment" do
    configured = Rails.application.config.x.jachegai[:database_path]
    assert_not_nil configured
    if ENV["DATABASE_PATH"].present?
      assert_equal ActiveRecord::Base.connection_db_config.database.to_s, configured.to_s
    else
      assert_match(/test\.sqlite3/, ActiveRecord::Base.connection_db_config.database.to_s)
    end
  end

  test "JWT secret is not the default placeholder in test" do
    secret = jachegai_config[:jwt_secret] || jachegai_config["jwt_secret"]
    assert_not_equal "change-me-in-production", secret.to_s
  end

  test "UTC timezone is configured" do
    assert_equal "UTC", Rails.application.config.time_zone.to_s
  end

  test "ISO-8601 date/time serialization" do
    time = Time.now.utc
    json = ActiveSupport::JSON.encode(time)
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, json)
  end

  test "locale is pt-BR" do
    assert_equal "pt-BR", I18n.locale.to_s
  end

  test "pt-BR locale file exists" do
    assert File.exist?(Rails.root.join("config", "locales", "pt-BR.yml"))
  end
end
