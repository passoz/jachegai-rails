class Api::V1::Seller::ProfileController < Api::V1::BaseController
  PROFILE_FIELDS = %i[
    name description contact_email contact_phone
    address_line1 address_city address_state address_zip address_country
  ].freeze

  before_action :parse_payload!, only: :update

  # GET /api/v1/seller/profile
  def show
    seller = require_seller!
    authorize!(seller, action: :show)
    render_success data: seller_payload(seller)
  end

  # PATCH /api/v1/seller/profile
  def update
    seller = require_seller!
    authorize!(seller, action: :update)
    PROFILE_FIELDS.each { |field| require_string_field!(field, allow_nil: true) }

    unless seller.update(@payload.slice(*PROFILE_FIELDS))
      return render_error(
        code: "invalid_input",
        message: I18n.t("errors.messages.invalid_input"),
        status: :unprocessable_content,
        context: { fields: seller.errors.to_hash }
      )
    end

    render_success data: seller_payload(seller)
  end

  private

  def parse_payload!
    super(allowed_fields: PROFILE_FIELDS)
  end

  def seller_payload(seller)
    {
      id: seller.id,
      name: seller.name,
      slug: seller.slug,
      description: seller.description,
      contact_email: seller.contact_email,
      contact_phone: seller.contact_phone,
      address_line1: seller.address_line1,
      address_city: seller.address_city,
      address_state: seller.address_state,
      address_zip: seller.address_zip,
      address_country: seller.address_country,
      moderation_state: seller.moderation_state
    }
  end
end
