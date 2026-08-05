module Api
  module V1
    module Public
      class CartsController < BaseController
        skip_before_action :authenticate!
        before_action :check_cart_mutation_rate_limit!, only: :destroy

        def show
          token = guest_token
          cart = find_guest_cart(token)

          return render_success(data: empty_cart_payload) if cart.nil? || cart.expired?

          render_success(data: serialize_cart(cart, token))
        end

        def destroy
          token = guest_token
          cart = find_guest_cart(token)
          return render_success(data: empty_cart_payload) unless cart
          return render_error(code: "expired", message: "carrinho expirado", status: :gone) if cart.expired?

          cart.with_lock do
            cart.guest_cart_items.destroy_all
            cart.update!(seller_id: nil)
          end

          render_success(data: serialize_cart(cart, token))
        end

        private

        def check_cart_mutation_rate_limit!
          token = guest_token
          check_rate_limit!(
            rate_limit_key("cart_mutation_ip"),
            rate_limit_key("cart_mutation_token", identifier: token.presence || "anonymous")
          )
        end

        def guest_token
          request.headers["X-Guest-Token"].presence
        end

        def find_guest_cart(token)
          return nil if token.blank?

          ::GuestCart.find_by(token_digest: Digest::SHA256.hexdigest(token))
        end

        def empty_cart_payload
          {
            cart_id: nil,
            token: nil,
            seller_id: nil,
            items: [],
            total_cents: 0
          }
        end

        def serialize_cart(cart, token)
          items = cart.guest_cart_items.includes(:product).order(:created_at, :id)
          total = items.sum { |item| item.quantity * item.product.price_cents }

          {
            cart_id: cart.id,
            token: token,
            seller_id: cart.seller_id,
            expires_at: cart.expires_at,
            items: items.map do |item|
              {
                id: item.id,
                product_id: item.product_id,
                product_name: item.product.name,
                unit_price_cents: item.product.price_cents,
                quantity: item.quantity,
                subtotal_cents: item.quantity * item.product.price_cents
              }
            end,
            total_cents: total
          }
        end
      end
    end
  end
end
