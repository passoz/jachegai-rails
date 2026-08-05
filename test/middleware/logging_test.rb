require "test_helper"

class LoggingTest < ActionDispatch::IntegrationTest
  test "Current.request_id is populated during request" do
    get "/healthz"
    assert response.headers["X-Request-ID"].present?
  end

  test "log format is configured from env" do
    assert_includes %w[text json], Rails.application.config.x.jachegai[:log_format]
  end

  test "log level is configured from env" do
    assert_includes %w[debug info warn error], Rails.application.config.x.jachegai[:log_level]
  end

  test "Current resets after request" do
    get "/healthz"
    assert_nil Current.request_id
  end
end

class LoggingFilterTest < ActiveSupport::TestCase
  test "filter parameters include sensitive keys" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    pattern = filter.instance_variable_get(:@regexps).to_s
    %w[password token session secret authorization cookie cvv].each do |key|
      assert_match(/#{key}/i, pattern, "filter_parameters must include #{key}")
    end
  end

  test "password is filtered from logs" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    result = filter.filter({ "password" => "super-secret", "name" => "João" })
    assert_equal "[FILTERED]", result["password"]
    assert_equal "João", result["name"]
  end
end
