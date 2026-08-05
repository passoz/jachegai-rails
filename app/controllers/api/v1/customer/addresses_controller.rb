class Api::V1::Customer::AddressesController < Api::V1::BaseController
  before_action :require_customer!
  before_action :set_address, only: [ :show, :update, :destroy, :make_default ]

  # GET /api/v1/customer/addresses
  def index
    scope = current_customer.addresses.order(is_default: :desc, created_at: :desc, id: :desc)
    pagination = paginate(scope)
    render_success(
      data: { addresses: pagination.records.map { |address| serialize_address(address) } },
      meta: pagination.meta
    )
  end

  # GET /api/v1/customer/addresses/:id
  def show
    render_success data: serialize_address(@address)
  end

  # POST /api/v1/customer/addresses
  def create
    allowed = [ :name, :line1, :city, :state, :zip, :country, :is_default ]
    return if parse_payload!(allowed_fields: allowed) == false

    require_payload_fields!(:name, :line1, :city, :state, :zip)
    %i[name line1 city state zip country].each { |f| require_string_field!(f) }
    require_boolean_field!(:is_default) if @payload.key?(:is_default)

    address = AddressService.create(customer: current_customer, params: @payload)
    render_success data: serialize_address(address), status: :created
  end

  # PATCH /api/v1/customer/addresses/:id
  def update
    allowed = [ :name, :line1, :city, :state, :zip, :country, :is_default ]
    return if parse_payload!(allowed_fields: allowed) == false

    %i[name line1 city state zip country].each { |f| require_string_field!(f) }
    require_boolean_field!(:is_default) if @payload.key?(:is_default)

    address = AddressService.update(address: @address, params: @payload)
    render_success data: serialize_address(address)
  end

  # DELETE /api/v1/customer/addresses/:id
  def destroy
    AddressService.destroy(address: @address)
    render_success data: { success: true }
  end

  # POST /api/v1/customer/addresses/:id/default
  def make_default
    address = AddressService.make_default(address: @address)
    render_success data: serialize_address(address)
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    Current.principal&.user&.customer || raise(ActiveRecord::RecordNotFound)
  end

  def set_address
    @address = current_customer.addresses.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @address
  end

  def serialize_address(address)
    {
      id: address.id,
      name: address.name,
      line1: address.line1,
      city: address.city,
      state: address.state,
      zip: address.zip,
      country: address.country,
      is_default: address.is_default,
      created_at: address.created_at
    }
  end
end
