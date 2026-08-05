module Api
  module V1
    module Admin
      class CouriersController < BaseController
        MODERATION_ACTIONS = %i[approve reject suspend reinstate].freeze

        before_action :ensure_admin!
        before_action :parse_moderation_payload!, only: MODERATION_ACTIONS
        before_action :set_courier, only: [ :show, *MODERATION_ACTIONS ]

        def index
          pagination = paginate(::Courier.order(created_at: :desc, id: :desc))
          render_success(data: { couriers: pagination.records.map { |courier| CourierSerializer.render(courier) } }, meta: pagination.meta)
        end

        def show
          render_success(data: CourierSerializer.render(@courier))
        end

        MODERATION_ACTIONS.each do |action|
          define_method(action) do
            courier = CourierModerationService.new(Current.principal).public_send(
              "#{action}!",
              @courier.id,
              reason: @payload[:reason],
              correlation_id: Current.request_id
            )
            render_success(data: CourierSerializer.render(courier))
          end
        end

        private

        def ensure_admin!
          return if Current.principal&.admin?

          raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
        end

        def parse_moderation_payload!
          parse_payload!(allowed_fields: %i[reason])
          require_string_field!(:reason, allow_nil: true) if @payload
        end

        def set_courier
          @courier = ::Courier.find(params[:id])
        end
      end
    end
  end
end
