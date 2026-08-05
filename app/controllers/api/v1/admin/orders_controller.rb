class Api::V1::Admin::OrdersController < Api::V1::BaseController
  before_action :require_admin!

  def index
    authorize!(Order, action: :index)
    scope = Order.includes(:customer, :seller, :payment, :order_items, :order_status_histories).order(created_at: :desc, id: :desc)
    pagination = paginate(scope)

    render_success(
      data: pagination.records.map { |order| OrderSerializer.as_json(order) },
      meta: pagination.meta
    )
  end

  def show
    order = Order.includes(:customer, :seller, :payment, :order_items, :order_status_histories).find(params[:id])
    authorize!(order, action: :show)

    render_success(data: OrderSerializer.as_json(order))
  end

  def cancel
    return unless parse_payload!(allowed_fields: [ :reason ])
    require_string_field!(:reason)

    order = Order.find(params[:id])
    authorize!(order, action: :cancel)

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
end
