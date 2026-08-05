class Api::V1::Customer::OrdersController < Api::V1::BaseController
  before_action :require_customer!

  def cancel
    # Stop immediately when strict parsing already rendered an error.
    return unless parse_payload!(allowed_fields: [ :reason ])
    require_string_field!(:reason)

    # Localiza o customer logado
    customer = Current.principal.user.customer
    raise ActiveRecord::RecordNotFound, "Order not found" if customer.nil?

    # Localiza o order dentro do escopo do customer (fail closed)
    order = customer.orders.find(params[:id])

    # Executa a transição
    OrderTransitionService.new(order, actor: Current.principal).transition_to!(
      "cancelled",
      reason: @payload[:reason],
      request_id: Current.request_id
    )

    render_success(data: {
      id: order.id,
      status: order.status,
      updated_at: order.updated_at
    })
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end
end
