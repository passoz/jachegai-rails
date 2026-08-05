# SellerOnboardingService creates a seller profile for an authenticated
# seller-role user. MVP rule: one seller per seller user, enforced here.
class SellerOnboardingService
  ALLOWED_PARAMS = %i[
    name description contact_email contact_phone
    address_line1 address_city address_state address_zip address_country
  ].freeze

  def self.onboard!(principal:, params:)
    user = principal.user
    unless user.has_role?(:seller)
      raise DomainError.new(code: :forbidden, http_status: :forbidden)
    end
    if principal.seller
      raise DomainError.new(code: :already_exists, context: { seller_id: principal.seller.id })
    end

    seller = nil
    ActiveRecord::Base.transaction do
      seller = Seller.create!(params.slice(*ALLOWED_PARAMS))
      SellerMembership.create!(seller: seller, user: user, role: "owner")
      SellerSettings.create!(seller: seller)
    end
    seller
  rescue ActiveRecord::RecordNotUnique
    existing_seller_id = SellerMembership.find_by(user: user)&.seller_id
    raise DomainError.new(code: :already_exists, context: { seller_id: existing_seller_id })
  end
end
