# Shared stub controller for API contract tests.
# Loaded explicitly by tests that need it: `require "support/api_test_controller"`.

# Dummy domain class so authorize!(TestApi, action:) resolves TestApiPolicy.
class TestApi; end

module Api
  module V1
    class TestApiController < Api::V1::BaseController
      def show
        render_success data: { id: "test-id", name: "Test" }
      end

      def raise_not_found
        raise ActiveRecord::RecordNotFound, "Record not found"
      end

      def raise_internal_error
        raise StandardError, "Something went wrong"
      end

      def echo
        render_success data: { received: json_body }
      end

      def echo_get
        render_success data: { method: request.method }
      end

      def protected_create
        authorize!(TestApi, action: :create)
        render_success data: { authorized: true }
      end

      private

      def json_body
        StrictJson.parse(
          request.raw_post,
          allowed_fields: %i[name],
          content_type: request.content_type,
          max_bytes: StrictJson::DEFAULT_MAX_BYTES
        )
      rescue StrictJson::Error => e
        raise DomainError.new(
          code: :invalid_input,
          http_status: e.http_status,
          context: { reason: e.code }
        )
      end
    end
  end
end
