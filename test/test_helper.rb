ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Reset the shared auth rate limiter before each test so cross-test
    # ordering cannot leak attempts between suites (RateLimitTest consumes
    # attempts on 127.0.0.1 that would otherwise 429 AuthControllerTest logins).
    setup do
      if defined?(Api::V1::BaseController)
        Api::V1::BaseController.shared_rate_limiter.store.reset
      end
    end

    # Add more helper methods to be used by all tests here...
  end
end
