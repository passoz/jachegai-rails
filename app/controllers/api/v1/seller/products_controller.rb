class Api::V1::Seller::ProductsController < Api::V1::BaseController
  PRODUCT_FIELDS = %i[name description price_cents currency category_id].freeze

  before_action :parse_payload!, only: [ :create, :update ]

  # GET /api/v1/seller/products
  def index
    seller = require_seller!
    authorize!(nil, action: :index)
    pagination = paginate(seller.products.ordered)
    render_success(
      data: { products: pagination.records.map { |product| product_payload(product) } },
      meta: pagination.meta
    )
  end

  # GET /api/v1/seller/products/:id
  def show
    seller = require_seller!
    product = seller.products.find(params[:id])
    authorize!(product, action: :show)
    render_success data: product_payload(product)
  end

  # POST /api/v1/seller/products
  def create
    seller = require_seller!
    authorize!(nil, action: :create)
    require_payload_fields!(:name, :price_cents, :currency)
    validate_product_payload!
    product = ProductService.create(seller: seller, params: @payload)
    render json: { ok: true, data: product_payload(product), meta: {} }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :unprocessable_content,
      context: { fields: e.record.errors.to_hash }
    )
  end

  # PATCH /api/v1/seller/products/:id
  def update
    seller = require_seller!
    product = seller.products.find(params[:id])
    authorize!(product, action: :update)
    validate_product_payload!
    product = ProductService.update(product: product, params: @payload)
    render_success data: product_payload(product)
  rescue ActiveRecord::RecordInvalid => e
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :unprocessable_content,
      context: { fields: e.record.errors.to_hash }
    )
  end

  # POST /api/v1/seller/products/:id/activate
  def activate
    seller = require_seller!
    product = seller.products.find(params[:id])
    authorize!(product, action: :activate)
    ProductService.set_active(product: product, active: true)
    render_success data: product_payload(product)
  end

  # POST /api/v1/seller/products/:id/deactivate
  def deactivate
    seller = require_seller!
    product = seller.products.find(params[:id])
    authorize!(product, action: :deactivate)
    ProductService.set_active(product: product, active: false)
    render_success data: product_payload(product)
  end

  # DELETE /api/v1/seller/products/:id
  def destroy
    seller = require_seller!
    product = seller.products.find(params[:id])
    authorize!(product, action: :destroy)
    ProductService.destroy(product: product)
    render_success data: { deleted: true }
  end

  private

  def parse_payload!
    super(allowed_fields: PRODUCT_FIELDS)
  end

  def validate_product_payload!
    %i[name description currency category_id].each { |field| require_string_field!(field, allow_nil: field.in?(%i[description category_id])) }
    require_integer_field!(:price_cents, minimum: 0) if @payload.key?(:price_cents)
  end

  def product_payload(product)
    {
      id: product.id,
      seller_id: product.seller_id,
      category_id: product.category_id,
      name: product.name,
      description: product.description,
      price_cents: product.price_cents,
      currency: product.currency,
      active: product.active,
      created_at: product.created_at&.iso8601
    }
  end
end
