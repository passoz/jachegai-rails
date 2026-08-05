class Api::V1::Seller::CategoriesController < Api::V1::BaseController
  CATEGORY_FIELDS = %i[name position].freeze

  before_action :parse_payload!, only: [ :create, :update, :reorder ]

  # GET /api/v1/seller/categories
  def index
    seller = require_seller!
    authorize!(nil, action: :index)
    pagination = paginate(seller.categories.ordered)
    render_success(
      data: { categories: pagination.records.map { |category| category_payload(category) } },
      meta: pagination.meta
    )
  end

  # GET /api/v1/seller/categories/:id
  def show
    seller = require_seller!
    category = seller.categories.find(params[:id])
    authorize!(category, action: :show)
    render_success data: category_payload(category)
  end

  # POST /api/v1/seller/categories
  def create
    seller = require_seller!
    authorize!(nil, action: :create)
    require_payload_fields!(:name)
    require_string_field!(:name)
    validate_position!
    category = CategoryService.create(seller: seller, params: @payload)
    render json: { ok: true, data: category_payload(category), meta: {} }, status: :created
  end

  # PATCH /api/v1/seller/categories/:id
  def update
    seller = require_seller!
    category = seller.categories.find(params[:id])
    authorize!(category, action: :update)
    require_string_field!(:name)
    validate_position!
    category = CategoryService.update(category: category, params: @payload)
    render_success data: category_payload(category)
  end

  # PUT /api/v1/seller/categories/order
  def reorder
    seller = require_seller!
    authorize!(nil, action: :reorder)
    require_string_array_field!(:ordered_ids)
    CategoryService.reorder(seller: seller, ordered_ids: @payload[:ordered_ids])
    render_success data: { ordered: true }
  end

  # DELETE /api/v1/seller/categories/:id
  def destroy
    seller = require_seller!
    category = seller.categories.find(params[:id])
    authorize!(category, action: :destroy)
    CategoryService.destroy(category: category)
    render_success data: { deleted: true }
  end

  private

  def parse_payload!
    super(allowed_fields: CATEGORY_FIELDS + [ :ordered_ids ])
  end

  def validate_position!
    require_integer_field!(:position, minimum: 0) if @payload.key?(:position)
  end

  def category_payload(category)
    {
      id: category.id,
      seller_id: category.seller_id,
      name: category.name,
      position: category.position
    }
  end
end
