class Api::V1::Seller::OrdersController < Api::V1::BaseController
  before_action :require_seller_role!
  before_action :require_seller!

  def index
    scope = current_seller.orders.order(created_at: :desc)
    paginated = paginate(scope)

    render_success(
      data: paginated.records.map { |o| serialize_order_summary(o) },
      meta: paginated.meta
    )
  end

  def show
    order = current_seller.orders.includes(:order_items, :order_status_histories).find(params[:id])
    render_success(data: serialize_order_detail(order))
  end

  def accept
    transition_to("accepted")
  end

  def reject
    return unless parse_payload!(allowed_fields: [ :reason ])

    require_string_field!(:reason)
    transition_to("rejected", reason: @payload[:reason])
  end

  def preparing
    transition_to("preparing")
  end

  def ready
    transition_to("ready")
  end

  private

  def require_seller_role!
    raise Forbidden unless Current.principal&.has_role?(:seller)
  end

  def transition_to(status, reason: nil)
    order = current_seller.orders.find(params[:id])

    OrderTransitionService.new(order, actor: Current.principal).transition_to!(
      status,
      reason: reason,
      request_id: Current.request_id
    )

    render_success(data: serialize_order_detail(order))
  end

  def serialize_order_summary(order)
    {
      id: order.id,
      status: order.status,
      currency: order.currency,
      total_cents: order.total_cents,
      created_at: order.created_at
    }
  end

  def serialize_order_detail(order)
    {
      id: order.id,
      status: order.status,
      currency: order.currency,
      subtotal_cents: order.subtotal_cents,
      delivery_fee_cents: order.delivery_fee_cents,
      discount_cents: order.discount_cents,
      courier_fee_cents: order.courier_fee_cents,
      total_cents: order.total_cents,
      address_name: order.address_name,
      address_line1: order.address_line1,
      address_city: order.address_city,
      address_state: order.address_state,
      address_zip: order.address_zip,
      address_country: order.address_country,
      created_at: order.created_at,
      items: order.order_items.map { |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents,
          subtotal_cents: item.subtotal_cents,
          currency: item.currency
        }
      },
      history: order.order_status_histories.order(occurred_at: :asc, id: :asc).map { |h|
        {
          id: h.id,
          from_status: h.from_status,
          to_status: h.to_status,
          reason: h.reason,
          occurred_at: h.occurred_at
        }
      }
    }
  end
end
