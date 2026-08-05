module Api
  module V1
    module Public
      class SellersController < BaseController
        skip_before_action :authenticate!

        def index
          sellers = ::Seller.where(moderation_state: "approved").order(:name, :id)
          paginated = paginate(sellers)

          render_success(
            data: paginated.records.map { |s| serialize_seller(s) },
            meta: { pagination: paginated.meta }
          )
        end

        def show
          seller = ::Seller.where(moderation_state: "approved").find_by(id: params[:id])
          return render_error(code: "not_found", message: "vendedor não encontrado ou indisponível", status: :not_found) unless seller

          render_success(data: serialize_seller(seller))
        end

        private

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
    end
  end
end
