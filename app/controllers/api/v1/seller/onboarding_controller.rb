class Api::V1::Seller::OnboardingController < Api::V1::BaseController
  ALLOWED_FIELDS = %i[
    name description contact_email contact_phone
    address_line1 address_city address_state address_zip address_country
  ].freeze

  before_action :parse_payload!, only: :create

  # POST /api/v1/seller/onboarding
  def create
    require_payload_fields!(:name)
    ALLOWED_FIELDS.each { |field| require_string_field!(field) }
    seller = SellerOnboardingService.onboard!(
      principal: Current.principal,
      params: @payload
    )
    render json: { ok: true, data: seller_payload(seller), meta: {} }, status: :created
  end

  private

  def parse_payload!
    super(allowed_fields: ALLOWED_FIELDS)
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
