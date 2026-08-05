class PaymentConfirmationService
  def initialize(payment, actor:)
    @payment = payment
    @actor = actor
  end

  def confirm_payment!
    raise ActiveRecord::RecordNotFound, "Payment not found" unless @actor.admin?

    Payment.transaction do
      @payment.lock!
      return @payment if @payment.state == "paid"

      validate_payment_state!
      order = Order.lock.find(@payment.order_id)
      validate_order_state!(order)

      amount = @payment.amount_cents
      currency = @payment.currency
      confirmed_at = Time.current

      @payment.update!(state: "paid")

      OutboxEvent.create!(
        event_key: "payment:#{@payment.id}:confirmed",
        event_type: "payment.confirmed",
        aggregate_type: "Payment",
        aggregate_id: @payment.id,
        payload: JSON.generate(
          payment_id: @payment.id,
          order_id: order.id,
          state: "paid",
          amount_cents: amount,
          currency: currency,
          confirmed_at: confirmed_at
        ),
        available_at: confirmed_at
      )

      AuditRecord.create!(
        action: "confirm_payment",
        actor_principal_id: "user:#{@actor.user.id}",
        resource_id: @payment.id,
        resource_type: "Payment",
        metadata: JSON.generate(
          order_id: order.id,
          amount_cents: amount,
          currency: currency
        )
      )
    end

    @payment
  end

  private

  def validate_payment_state!
    return unless %w[failed refunded].include?(@payment.state)

    raise DomainError.new(
      code: :payment_conflict,
      message: "Cannot confirm payment in state #{@payment.state}",
      http_status: :conflict
    )
  end

  def validate_order_state!(order)
    return unless %w[cancelled rejected].include?(order.status)

    raise DomainError.new(
      code: :order_conflict,
      message: "Cannot confirm payment for an order in status #{order.status}",
      http_status: :conflict
    )
  end
end
