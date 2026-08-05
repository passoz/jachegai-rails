class Api::V1::Admin::SellersController < Api::V1::BaseController
  MODERATION_ACTIONS = %w[approve reject suspend reinstate].freeze

  before_action :require_admin!
  before_action :parse_payload!, only: MODERATION_ACTIONS.map(&:to_sym)
  before_action :set_seller, only: [ :show ] + MODERATION_ACTIONS.map(&:to_sym)

  # GET /api/v1/admin/sellers
  def index
    authorize!(nil, action: :index)
    pagination = paginate(Seller.order(created_at: :desc, id: :desc))
    render_success data: { sellers: pagination.records.map { |seller| seller_payload(seller) } }, meta: pagination.meta
  end

  # GET /api/v1/admin/sellers/:id
  def show
    authorize!(@seller, action: :show)
    render_success data: seller_payload(@seller)
  end

  MODERATION_ACTIONS.each do |action|
    define_method(action) do
      authorize!(@seller, action: action)
      require_string_field!(:reason)
      ModerationService.transition(
        seller: @seller,
        action: action,
        actor: Current.principal,
        reason: @payload[:reason],
        correlation_id: Current.request_id
      )
      render_success data: seller_payload(@seller)
    end
  end

  private

  def set_seller
    @seller = Seller.find(params[:id])
  end

  def parse_payload!
    super(allowed_fields: [ :reason ])
  end

  def seller_payload(seller)
    {
      id: seller.id,
      name: seller.name,
      slug: seller.slug,
      description: seller.description,
      contact_email: seller.contact_email,
      moderation_state: seller.moderation_state,
      moderated_at: seller.moderated_at&.iso8601,
      created_at: seller.created_at&.iso8601
    }
  end
end
