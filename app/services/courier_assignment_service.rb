class CourierAssignmentService
  OPERATION = "courier_assignment".freeze

  def initialize(principal)
    @principal = principal
  end

  def accept_order!(order_id, idempotency_key:, request_id: nil)
    unless @principal&.has_role?("courier")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    courier = @principal.user.courier
    unless courier
      raise DomainError.new(code: :not_found, message: "Courier profile not found", http_status: :not_found)
    end

    IdempotencyService.execute(
      principal_id: @principal.user.id,
      operation: OPERATION,
      key: idempotency_key,
      payload: { order_id: order_id }
    ) do |idempotency_record|
      perform_assignment!(
        order_id: order_id,
        courier: courier,
        idempotency_record: idempotency_record,
        request_id: request_id
      )
    end
  end

  private

  def perform_assignment!(order_id:, courier:, idempotency_record:, request_id:)
    order = nil

    Order.transaction do
      courier = Courier.lock.find(courier.id)
      unless courier.approved?
        raise DomainError.new(
          code: :courier_not_approved,
          message: "Only approved couriers can accept orders",
          http_status: :unprocessable_content
        )
      end
      unless courier.available?
        raise DomainError.new(
          code: :courier_not_available,
          message: "Courier must be available to accept an order",
          http_status: :conflict
        )
      end

      order = Order.lock.find_by(id: order_id)
      unless order
        raise DomainError.new(code: :not_found, message: "Order not found", http_status: :not_found)
      end

      if courier.on_delivery?
        raise DomainError.new(
          code: :active_delivery_in_progress,
          message: "Courier already has an active delivery in progress",
          http_status: :conflict
        )
      end

      unless order.status == "ready" && order.courier_id.nil?
        raise DomainError.new(
          code: :order_already_assigned,
          message: "Order is not ready or already assigned to another courier",
          http_status: :conflict
        )
      end

      occurred_at = Time.current
      assigned_rows = Order.where(id: order.id, status: "ready", courier_id: nil).update_all(
        status: "assigned",
        courier_id: courier.id,
        updated_at: occurred_at
      )
      unless assigned_rows == 1
        raise DomainError.new(
          code: :order_already_assigned,
          message: "Order is not ready or already assigned to another courier",
          http_status: :conflict
        )
      end
      order.reload
      courier.update!(operational_state: "on_delivery")

      OrderStatusHistory.create!(
        order: order,
        from_status: "ready",
        to_status: "assigned",
        actor_principal_id: "user:#{@principal.user.id}",
        request_id: request_id,
        occurred_at: occurred_at
      )

      OutboxEvent.create!(
        event_key: "order:#{order.id}:transition:ready_to_assigned",
        event_type: "order.assigned",
        aggregate_type: "Order",
        aggregate_id: order.id,
        payload: JSON.generate(
          order_id: order.id,
          courier_id: courier.id,
          from_status: "ready",
          to_status: "assigned",
          occurred_at: occurred_at
        ),
        available_at: occurred_at
      )

      IdempotencyService.complete!(idempotency_record, resource: order, response_status: 200)
    end

    order
  end
end
