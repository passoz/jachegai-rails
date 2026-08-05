module Api
  module V1
    module Courier
      class OrdersController < BaseController
        before_action :ensure_courier!

        def eligible
          unless @current_courier.approved? && @current_courier.available?
            raise DomainError.new(
              code: :courier_not_available,
              message: "Courier must be approved and available to view eligible orders",
              http_status: :unprocessable_content
            )
          end

          orders = Order.where(status: "ready", courier_id: nil).order(created_at: :asc, id: :asc)
          paginated = paginate(orders)

          render_success(
            data: paginated.records.map { |order| CourierOrderSerializer.eligible(order) },
            meta: paginated.meta
          )
        end

        def active
          order = Order.where(courier_id: @current_courier.id, status: %w[assigned picked_up]).preload(:order_items, :payment).order(updated_at: :desc, id: :desc).first
          data = order ? OrderSerializer.as_json(order) : nil
          render_success(data: data)
        end

        def history
          orders = Order.where(courier_id: @current_courier.id, status: "delivered").preload(:order_items, :payment).order(updated_at: :desc, id: :desc)
          paginated = paginate(orders)

          render_success(
            data: paginated.records.map { |o| OrderSerializer.as_json(o) },
            meta: paginated.meta
          )
        end

        def accept
          order = CourierAssignmentService.new(Current.principal).accept_order!(
            params[:id],
            idempotency_key: require_idempotency_key!,
            request_id: Current.request_id
          )
          render_success(data: OrderSerializer.as_json(order))
        end

        def pickup
          order = CourierDeliveryTransitionService.new(Current.principal).pickup!(params[:id], request_id: Current.request_id)
          render_success(data: OrderSerializer.as_json(order))
        end

        def deliver
          order = CourierDeliveryTransitionService.new(Current.principal).deliver!(params[:id], request_id: Current.request_id)
          render_success(data: OrderSerializer.as_json(order))
        end

        private

        def require_idempotency_key!
          key = request.headers["Idempotency-Key"].to_s
          return key if key.present? && key.bytesize <= 128

          invalid_payload_field!(:idempotency_key)
        end

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
