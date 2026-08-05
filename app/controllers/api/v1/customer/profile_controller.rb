class Api::V1::Customer::ProfileController < Api::V1::BaseController
  before_action :require_customer!

  # GET /api/v1/customer/profile
  def show
    authorize!(current_customer, action: :show)
    render_success data: serialize_customer(current_customer)
  end

  # PATCH /api/v1/customer/profile
  def update
    return if parse_payload!(allowed_fields: [ :full_name, :email, :phone ]) == false

    require_payload_fields!(:full_name, :email)
    require_string_field!(:full_name)
    require_string_field!(:email)
    require_string_field!(:phone, allow_nil: true)

    authorize!(current_customer, action: :update)
    customer = CustomerProfileService.update(customer: current_customer, params: @payload)
    render_success data: serialize_customer(customer)
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_user
    Current.principal&.user
  end

  def current_customer
    current_user.customer || raise(ActiveRecord::RecordNotFound)
  end

  def serialize_customer(customer)
    {
      id: customer.id,
      user_id: customer.user_id,
      email: customer.user.email,
      full_name: customer.full_name,
      phone: customer.phone,
      active: customer.user.active,
      created_at: customer.created_at,
      updated_at: customer.updated_at
    }
  end
end
