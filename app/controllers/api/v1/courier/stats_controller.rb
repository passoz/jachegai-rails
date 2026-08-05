module Api
  module V1
    module Courier
      class StatsController < BaseController
        before_action :ensure_courier!

        def show
          delivered_orders = Order.where(courier_id: @current_courier.id, status: "delivered")

          completed_count = delivered_orders.count
          earnings = delivered_orders.group(:currency).order(:currency).sum(:courier_fee_cents).map do |currency, amount_cents|
            { currency: currency, amount_cents: amount_cents }
          end

          render_success(
            data: {
              completed_deliveries_count: completed_count,
              earnings: earnings
            }
          )
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
