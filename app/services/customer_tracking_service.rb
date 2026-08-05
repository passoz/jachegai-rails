class CustomerTrackingService
  ACTIVE_ORDER_STATES = %w[assigned picked_up].freeze

  def initialize(principal)
    @principal = principal
  end

  def get_tracking(order_id)
    unless @principal&.has_role?("customer")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    customer = @principal.user.customer
    unless customer
      raise ActiveRecord::RecordNotFound, "Customer profile not found"
    end

    order = Order.find_by(id: order_id, customer_id: customer.id)
    unless order
      raise ActiveRecord::RecordNotFound, "Order not found"
    end

    history = order.order_status_histories.order(occurred_at: :asc, id: :asc).map do |entry|
      {
        from_status: entry.from_status,
        to_status: entry.to_status,
        occurred_at: entry.occurred_at.iso8601
      }
    end

    location_data = nil
    freshness_seconds = nil

    if order.courier_id.present? && ACTIVE_ORDER_STATES.include?(order.status)
      latest_location = CourierLocation.where(courier_id: order.courier_id).order(recorded_at: :desc).first
      if latest_location
        location_data = {
          latitude: latest_location.latitude,
          longitude: latest_location.longitude,
          accuracy_meters: latest_location.accuracy_meters,
          recorded_at: latest_location.recorded_at.iso8601
        }
        freshness_seconds = (Time.current - latest_location.recorded_at).to_i
      end
    end

    {
      order_id: order.id,
      order_state: order.status,
      history: history,
      location: location_data,
      freshness_seconds: freshness_seconds
    }
  end
end
