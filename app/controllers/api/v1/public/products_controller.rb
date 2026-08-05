module Api
  module V1
    module Public
      class ProductsController < BaseController
        skip_before_action :authenticate!

        def index
          seller = ::Seller.where(moderation_state: "approved").find_by(id: params[:seller_id])
          return render_error(code: "not_found", message: "vendedor não encontrado ou indisponível", status: :not_found) unless seller

          products = ::Product.joins(:inventory_item)
                              .where(seller: seller, active: true)
                              .where("inventory_items.quantity > 0")
                              .order(:name, :id)

          paginated = paginate(products)

          render_success(
            data: paginated.records.map { |p| serialize_product(p) },
            meta: { pagination: paginated.meta }
          )
        end

        def show
          product = ::Product.joins(:seller, :inventory_item)
                             .where(sellers: { moderation_state: "approved" }, active: true)
                             .where("inventory_items.quantity > 0")
                             .find_by(id: params[:id])

          return render_error(code: "not_found", message: "produto não encontrado ou indisponível", status: :not_found) unless product

          render_success(data: serialize_product(product))
        end

        private

        def serialize_product(product)
          inv = product.inventory_item
          {
            id: product.id,
            seller_id: product.seller_id,
            category_id: product.category_id,
            name: product.name,
            description: product.description,
            price_cents: product.price_cents,
            currency: product.currency,
            available_quantity: inv ? inv.quantity : 0
          }
        end
      end
    end
  end
end
