class Api::V1::Customer::FavoritesController < Api::V1::BaseController
  before_action :require_customer!

  # GET /api/v1/customer/favorites
  def index
    scope = current_customer.favorites.joins(:seller).includes(:seller).order("sellers.name ASC", "sellers.id ASC")
    pagination = paginate(scope)
    render_success(
      data: { favorites: pagination.records.map { |favorite| serialize_seller(favorite.seller) } },
      meta: pagination.meta
    )
  end

  # POST /api/v1/customer/favorites
  def create
    return if parse_payload!(allowed_fields: [ :seller_id ]) == false
    require_payload_fields!(:seller_id)
    require_string_field!(:seller_id)

    favorite = FavoriteService.add(customer: current_customer, seller_id: @payload[:seller_id])
    render_success data: serialize_seller(favorite.seller), status: :created
  end

  # DELETE /api/v1/customer/favorites/:id
  # Mapeamos o :id como o seller_id para ficar amigável para o cliente.
  def destroy
    FavoriteService.remove(customer: current_customer, seller_id: params[:id])
    render_success data: { success: true }
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    Current.principal&.user&.customer || raise(ActiveRecord::RecordNotFound)
  end

  def serialize_seller(seller)
    {
      id: seller.id,
      name: seller.name,
      slug: seller.slug,
      contact_email: seller.contact_email,
      created_at: seller.created_at
    }
  end
end
