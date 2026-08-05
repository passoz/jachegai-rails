module Api
  module V1
    module Courier
      class LocationsController < BaseController
        LOCATION_FIELDS = %i[latitude longitude accuracy_meters].freeze

        def create
          return unless parse_payload!(allowed_fields: LOCATION_FIELDS)
          require_payload_fields!(:latitude, :longitude)

          unless @payload[:latitude].is_a?(Numeric) && @payload[:longitude].is_a?(Numeric)
            raise DomainError.new(
              code: :invalid_input,
              message: "Latitude and longitude must be numbers",
              http_status: :unprocessable_content
            )
          end

          if @payload.key?(:accuracy_meters) && !@payload[:accuracy_meters].nil? && !@payload[:accuracy_meters].is_a?(Numeric)
            raise DomainError.new(
              code: :invalid_input,
              message: "Accuracy meters must be a number",
              http_status: :unprocessable_content
            )
          end

          service = CourierLocationService.new(Current.principal)
          location = service.record_location!(
            latitude: @payload[:latitude],
            longitude: @payload[:longitude],
            accuracy_meters: @payload[:accuracy_meters]
          )

          render_success(data: CourierLocationSerializer.render(location), status: :created)
        end
      end
    end
  end
end
