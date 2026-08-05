module Api
  module V1
    module Courier
      class AvailabilityController < BaseController
        def update
          return unless parse_payload!(allowed_fields: %i[state])
          require_payload_fields!(:state)

          service = CourierAvailabilityService.new(Current.principal)
          courier = service.set_availability!(state: @payload[:state])

          render_success(data: CourierSerializer.render(courier))
        end
      end
    end
  end
end
