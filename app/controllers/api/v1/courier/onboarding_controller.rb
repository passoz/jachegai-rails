module Api
  module V1
    module Courier
      class OnboardingController < BaseController
        ONBOARDING_FIELDS = %i[phone document_number vehicle_type vehicle_plate location_consent].freeze

        def create
          return unless parse_payload!(allowed_fields: ONBOARDING_FIELDS)
          require_payload_fields!(:phone, :document_number, :vehicle_type)
          require_string_field!(:phone)
          require_string_field!(:document_number)
          require_string_field!(:vehicle_type)
          require_string_field!(:vehicle_plate, allow_nil: true)
          require_boolean_field!(:location_consent)

          service = CourierOnboardingService.new(Current.principal)
          courier = service.onboard!(@payload)

          render_success(data: CourierSerializer.render(courier), status: :created)
        end
      end
    end
  end
end
