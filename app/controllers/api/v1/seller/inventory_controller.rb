class Api::V1::Seller::InventoryController < Api::V1::BaseController
  before_action :parse_payload!, only: :update

  # GET /api/v1/seller/inventory
  def index
    seller = require_seller!
    authorize!(nil, action: :index)
    scope = seller.inventory_items.includes(:product).order(created_at: :desc, id: :desc)
    pagination = paginate(scope)
    render_success(
      data: { inventory: pagination.records.map { |item| inventory_payload(item) } },
      meta: pagination.meta
    )
  end

  # PATCH /api/v1/seller/inventory/:product_id
  def update
    seller = require_seller!
    product = seller.products.find(params[:product_id])
    authorize!(nil, action: :update)
    quantity = require_integer_field!(:quantity, minimum: 0)
    item = InventoryService.set_quantity(
      seller: seller,
      product: product,
      quantity: quantity
    )
    render_success data: inventory_payload(item)
  rescue ActiveRecord::RecordInvalid => e
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :unprocessable_content,
      context: { fields: e.record.errors.to_hash }
    )
  end

  private

  def parse_payload!
    super(allowed_fields: [ :quantity ])
  end

  def inventory_payload(item)
    {
      id: item.id,
      seller_id: item.seller_id,
      product_id: item.product_id,
      product_name: item.product&.name,
      quantity: item.quantity
    }
  end
end
