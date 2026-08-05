class CourierDeliveryTransitionService
  def initialize(principal)
    @principal = principal
  end

  def pickup!(order_id, request_id: nil)
    transition!(order_id, target_status: "picked_up", request_id: request_id)
  end

  def deliver!(order_id, request_id: nil)
    transition!(order_id, target_status: "delivered", request_id: request_id)
  end

  private

  def transition!(order_id, target_status:, request_id:)
    unless @principal&.has_role?("courier")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    courier_id = @principal.user.courier&.id
    raise ActiveRecord::RecordNotFound, "Order not found" if courier_id.nil?

    order = nil
    Order.transaction do
      courier = Courier.lock.find(courier_id)
      order = Order.lock.find_by!(id: order_id, courier_id: courier.id)

      return order if order.status == target_status

      unless OrderStateMachine.transition_allowed?(from: order.status, to: target_status)
        raise DomainError.new(
          code: :invalid_transition,
          message: "Cannot transition order from #{order.status} to #{target_status}",
          http_status: :conflict
        )
      end

      occurred_at = Time.current
      from_status = order.status
      order.update!(status: target_status)

      if target_status == "delivered"
        next_operational_state = courier.approved? ? "available" : "offline"
        courier.update!(operational_state: next_operational_state)
      end

      OrderStatusHistory.create!(
        order: order,
        from_status: from_status,
        to_status: target_status,
        actor_principal_id: "user:#{@principal.user.id}",
        request_id: request_id,
        occurred_at: occurred_at
      )

      OutboxEvent.create!(
        event_key: "order:#{order.id}:transition:#{from_status}_to_#{target_status}",
        event_type: "order.#{target_status}",
        aggregate_type: "Order",
        aggregate_id: order.id,
        payload: JSON.generate(
          order_id: order.id,
          courier_id: courier.id,
          from_status: from_status,
          to_status: target_status,
          occurred_at: occurred_at
        ),
        available_at: occurred_at
      )
    end

    order
  end
end
