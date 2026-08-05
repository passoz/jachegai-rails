class OrderTransitionService
  def initialize(order, actor:)
    @order = order
    @actor = actor
  end

  def transition_to!(new_status, reason: nil, request_id: nil)
    Order.transaction do
      @order.lock!
      validate_actor_ownership!(new_status)

      from_status = @order.status
      validate_cancellation_reason!(reason) if new_status == "cancelled"
      if from_status == new_status
        validate_idempotent_target_capability!(new_status)
        return @order
      end

      payment = Payment.lock.find_by(order_id: @order.id)
      validate_cancellation!(from_status, payment) if new_status == "cancelled"
      validate_rejection!(payment) if new_status == "rejected"
      validate_state_transition!(from_status, new_status)
      validate_actor_capability!(from_status, new_status)
      validate_acceptance!(payment) if new_status == "accepted"

      occurred_at = Time.current
      @order.update!(status: new_status)
      release_assigned_courier! if from_status == "assigned" && new_status == "cancelled"

      if %w[cancelled rejected].include?(new_status)
        restore_inventory_if_needed!
        fail_pending_payment_if_needed!(new_status, payment)
      end

      @order.order_status_histories.create!(
        from_status: from_status,
        to_status: new_status,
        actor_principal_id: actor_identity_string,
        reason: reason,
        request_id: request_id,
        occurred_at: occurred_at
      )

      OutboxEvent.create!(
        event_key: "order:#{@order.id}:transition:#{from_status}_to_#{new_status}",
        event_type: "order.#{new_status}",
        aggregate_type: "Order",
        aggregate_id: @order.id,
        payload: JSON.generate(
          order_id: @order.id,
          status: new_status,
          from_status: from_status,
          to_status: new_status,
          reason: reason,
          occurred_at: occurred_at
        ),
        available_at: occurred_at
      )
    end

    @order
  end

  private

  def validate_cancellation_reason!(reason)
    return unless customer_actor? && reason.to_s.strip.blank?

    raise DomainError.new(
      code: :reason_required,
      message: "Reason is required to cancel this order",
      http_status: :unprocessable_content
    )
  end

  def validate_cancellation!(from_status, payment)
    if customer_actor?
      if from_status != "pending"
        raise DomainError.new(
          code: :invalid_transition,
          message: "Customers can only cancel orders in pending status",
          http_status: :unprocessable_content
        )
      end
    end

    if payment&.state == "paid"
      raise DomainError.new(
        code: :refund_required,
        message: "Paid orders cannot be cancelled without refund capability",
        http_status: :conflict
      )
    end

    if (customer_actor? || @actor.admin? || @actor.system?) && payment&.state != "pending"
      raise DomainError.new(
        code: :payment_conflict,
        message: "Cancellation requires a pending payment",
        http_status: :conflict
      )
    end
  end

  def validate_rejection!(payment)
    return unless payment&.state == "paid"

    raise DomainError.new(
      code: :refund_required,
      message: "Paid orders cannot be rejected without refund capability",
      http_status: :conflict
    )
  end

  def validate_state_transition!(from_status, new_status)
    return if OrderStateMachine.transition_allowed?(from: from_status, to: new_status)

    raise DomainError.new(
      code: :invalid_transition,
      message: "Transition from #{from_status} to #{new_status} is not allowed",
      http_status: :unprocessable_content
    )
  end

  def validate_acceptance!(payment)
    return if payment&.state == "paid"

    raise DomainError.new(
      code: :payment_required,
      message: "Payment must be paid before order can be accepted",
      http_status: :unprocessable_content
    )
  end

  def release_assigned_courier!
    return if @order.courier_id.nil?

    courier = Courier.lock.find(@order.courier_id)
    next_state = courier.approved? ? "available" : "offline"
    courier.update!(operational_state: next_state)
  end

  def restore_inventory_if_needed!
    @order.order_items.each do |item|
      next if item.product_id.nil? # Produto deletado não tem estoque a restaurar

      # Verifica de forma idempotente se já foi restaurado
      already_restored = InventoryMovement.exists?(
        order_id: @order.id,
        product_id: item.product_id,
        kind: "restore"
      )
      next if already_restored

      # Localiza o item de estoque e bloqueia para update
      inventory_item = InventoryItem.find_by(
        product_id: item.product_id,
        seller_id: item.seller_id
      )
      next if inventory_item.nil?

      inventory_item.lock!
      new_quantity = inventory_item.quantity + item.quantity
      inventory_item.update!(quantity: new_quantity)

      # Registra a movimentação de restore
      InventoryMovement.create!(
        order_id: @order.id,
        product_id: item.product_id,
        seller_id: item.seller_id,
        kind: "restore",
        quantity: item.quantity,
        balance_after: new_quantity
      )
    end
  end

  def fail_pending_payment_if_needed!(status, payment)
    return if payment.nil?

    if payment.state == "pending"
      error_code = status == "cancelled" ? "order_cancelled" : "order_rejected"
      payment.update!(state: "failed", last_error_code: error_code)

      # Cria outbox event do pagamento falhado
      OutboxEvent.create!(
        event_key: "payment:#{payment.id}:failed:due_to_#{status}",
        event_type: "payment.failed",
        aggregate_type: "Payment",
        aggregate_id: payment.id,
        payload: JSON.generate(
          payment_id: payment.id,
          order_id: @order.id,
          state: "failed",
          error_code: error_code,
          occurred_at: Time.current
        ),
        available_at: Time.current
      )
    end
  end

  def validate_idempotent_target_capability!(status)
    allowed =
      if status == "cancelled"
        @actor.system? || @actor.admin? || customer_actor?
      elsif %w[accepted rejected preparing ready].include?(status)
        @actor.has_role?("seller")
      else
        false
      end

    return if allowed

    forbidden_transition!
  end

  def validate_actor_capability!(from_status, new_status)
    allowed =
      if @actor.system?
        from_status == "pending" && new_status == "cancelled"
      elsif @actor.admin?
        %w[accepted assigned].include?(from_status) && new_status == "cancelled"
      elsif customer_actor? && from_status == "pending" && new_status == "cancelled"
        true
      elsif @actor.has_role?("seller")
        [
          [ "pending", "accepted" ],
          [ "pending", "rejected" ],
          [ "accepted", "preparing" ],
          [ "preparing", "ready" ]
        ].include?([ from_status, new_status ])
      else
        false
      end

    return if allowed

    forbidden_transition!
  end

  def forbidden_transition!
    raise DomainError.new(
      code: :forbidden_transition,
      message: "Actor is not authorized for this order transition",
      http_status: :forbidden
    )
  end

  def validate_actor_ownership!(new_status)
    if @actor.admin? || @actor.system?
      # Admin has global access; the system principal is restricted by capability.
    elsif new_status == "cancelled" && @actor.has_role?("customer")
      customer = @actor.user.customer
      raise ActiveRecord::RecordNotFound, "Order not found" if customer.nil? || @order.customer_id != customer.id
    elsif @actor.has_role?("seller")
      member_seller_ids = @actor.user.seller_memberships.pluck(:seller_id)
      raise ActiveRecord::RecordNotFound, "Order not found" unless member_seller_ids.include?(@order.seller_id)
    else
      raise ActiveRecord::RecordNotFound, "Order not found"
    end
  end

  def customer_actor?
    !@actor.admin? && !@actor.system? && @actor.has_role?("customer")
  end

  def actor_identity_string
    if @actor.user
      "user:#{@actor.user.id}"
    else
      "system"
    end
  end
end
