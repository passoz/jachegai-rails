module Api
  module V1
    module Public
      class CartItemsController < BaseController
        skip_before_action :authenticate!
        before_action :check_cart_mutation_rate_limit!

        def create
          parse_payload!(allowed_fields: [ :product_id, :quantity, :replace_confirmed ]) || return
          require_payload_fields!(:product_id, :quantity)
          product_id = require_string_field!(:product_id)
          quantity = require_cart_quantity!(:quantity, minimum: 1)
          replace_confirmed = require_boolean_field!(:replace_confirmed) || false
          product = available_product(product_id)
          return unavailable_product_error unless product

          token, cart = resolve_or_create_cart

          ActiveRecord::Base.transaction do
            cart.lock!
            product = available_product(product_id)
            return unavailable_product_error unless product

            current_item = cart.guest_cart_items.find_by(product_id: product.id)
            resulting_quantity = (current_item&.quantity || 0) + quantity
            validate_available_quantity!(product, resulting_quantity)

            if cart.seller_id.present? && cart.seller_id != product.seller_id
              return seller_conflict_error(cart, product) unless replace_confirmed

              cart.guest_cart_items.destroy_all
              cart.update!(seller: product.seller)
              current_item = nil
            elsif cart.seller_id.nil?
              cart.update!(seller: product.seller)
            end

            item = current_item || cart.guest_cart_items.build(product: product, seller: product.seller)
            item.quantity = resulting_quantity
            item.save!
          end

          render_success(data: serialize_cart(cart, token), status: :created)
        end

        def update
          parse_payload!(allowed_fields: [ :quantity ]) || return
          require_payload_fields!(:quantity)
          quantity = require_cart_quantity!(:quantity, minimum: 0)
          token = guest_token
          cart = find_guest_cart(token)
          return render_error(code: "not_found", message: "carrinho não encontrado", status: :not_found) unless cart
          return render_error(code: "expired", message: "carrinho expirado", status: :gone) if cart.expired?

          cart.with_lock do
            item = cart.guest_cart_items.find_by(id: params[:id])
            return render_error(code: "not_found", message: "item do carrinho não encontrado", status: :not_found) unless item

            if quantity.zero?
              item.destroy!
              cart.update!(seller_id: nil) if cart.guest_cart_items.reload.empty?
            else
              product = available_product(item.product_id)
              return unavailable_product_error unless product

              validate_available_quantity!(product, quantity)
              item.update!(quantity: quantity)
            end
          end

          render_success(data: serialize_cart(cart, token))
        end

        def destroy
          token = guest_token
          cart = find_guest_cart(token)
          return render_error(code: "not_found", message: "carrinho não encontrado", status: :not_found) unless cart
          return render_error(code: "expired", message: "carrinho expirado", status: :gone) if cart.expired?

          cart.with_lock do
            item = cart.guest_cart_items.find_by(id: params[:id])
            return render_error(code: "not_found", message: "item do carrinho não encontrado", status: :not_found) unless item

            item.destroy!
            cart.update!(seller_id: nil) if cart.guest_cart_items.reload.empty?
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

        def resolve_or_create_cart
          token = guest_token
          cart = find_guest_cart(token)

          if cart.nil? || cart.expired?
            token, digest = ::GuestCart.generate_token
            cart = ::GuestCart.create!(token_digest: digest)
          end

          [ token, cart ]
        end

        def available_product(product_id)
          ::Product.joins(:seller, :inventory_item)
                   .where(sellers: { moderation_state: "approved" }, active: true)
                   .find_by(id: product_id)
        end

        def require_cart_quantity!(field, minimum:)
          quantity = require_integer_field!(field, minimum: minimum)
          return quantity if quantity <= ::GuestCartItem::MAX_QUANTITY

          invalid_payload_field!(field)
        end

        def validate_available_quantity!(product, quantity)
          inventory = product.inventory_item
          return if inventory && inventory.quantity >= quantity

          raise DomainError.new(
            code: :invalid_input,
            http_status: :unprocessable_content,
            context: { fields: { quantity: [ I18n.t("errors.messages.invalid") ] } }
          )
        end

        def unavailable_product_error
          render_error(
            code: "invalid_input",
            message: "produto indisponível ou estoque insuficiente",
            status: :unprocessable_content
          )
        end

        def seller_conflict_error(cart, product)
          render_error(
            code: "seller_conflict",
            message: "seu carrinho contém itens de outro vendedor",
            status: :conflict,
            context: { current_seller_id: cart.seller_id, new_seller_id: product.seller_id }
          )
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
