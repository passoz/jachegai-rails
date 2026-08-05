module Api
  module V1
    module Courier
      class ProfileController < BaseController
        PROFILE_FIELDS = %i[phone vehicle_type vehicle_plate location_consent].freeze

        before_action :ensure_courier!

        def show
          render_success(data: CourierSerializer.render(@current_courier))
        end

        def update
          return unless parse_payload!(allowed_fields: PROFILE_FIELDS)
          require_string_field!(:phone, allow_nil: true)
          require_string_field!(:vehicle_type, allow_nil: true)
          require_string_field!(:vehicle_plate, allow_nil: true)
          require_boolean_field!(:location_consent)

          if @payload.key?(:location_consent)
            consent = @payload.delete(:location_consent)
            @payload[:location_consent_given_at] = consent ? Time.current : nil
          end

          unless @current_courier.update(@payload)
            raise DomainError.new(
              code: :invalid_input,
              message: @current_courier.errors.full_messages.join(", "),
              http_status: :unprocessable_content,
              context: { fields: @current_courier.errors.to_hash }
            )
          end

          render_success(data: CourierSerializer.render(@current_courier))
        end

        private

        def ensure_courier!
          unless Current.principal&.has_role?("courier")
            raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
          end

          @current_courier = Current.principal.user.courier
          unless @current_courier
            raise DomainError.new(code: :not_found, message: "Courier profile not found", http_status: :not_found)
          end
        end
      end
    end
  end
end
