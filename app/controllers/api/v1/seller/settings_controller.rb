class Api::V1::Seller::SettingsController < Api::V1::BaseController
  SETTINGS_FIELDS = %i[currency auto_accept_orders preparation_time_minutes].freeze

  before_action :parse_payload!, only: :update

  # GET /api/v1/seller/settings
  def show
    seller = require_seller!
    authorize!(seller, action: :show)
    render_success data: settings_payload(seller.settings || SellerSettings.new(seller: seller))
  end

  # PATCH /api/v1/seller/settings
  def update
    seller = require_seller!
    authorize!(seller, action: :update)
    require_string_field!(:currency)
    require_boolean_field!(:auto_accept_orders)
    if @payload.key?(:preparation_time_minutes)
      require_integer_field!(:preparation_time_minutes, minimum: 0)
    end

    settings = seller.settings || SellerSettings.create!(seller: seller)
    unless settings.update(@payload.slice(*SETTINGS_FIELDS))
      return render_error(
        code: "invalid_input",
        message: I18n.t("errors.messages.invalid_input"),
        status: :unprocessable_content,
        context: { fields: settings.errors.to_hash }
      )
    end

    render_success data: settings_payload(settings)
  end

  private

  def parse_payload!
    super(allowed_fields: SETTINGS_FIELDS)
  end

  def settings_payload(settings)
    {
      id: settings.id,
      seller_id: settings.seller_id,
      currency: settings.currency,
      auto_accept_orders: settings.auto_accept_orders,
      preparation_time_minutes: settings.preparation_time_minutes
    }
  end
end
