class Api::V1::Customer::CheckoutsController < Api::V1::BaseController
  before_action :require_customer!

  def self.checkout_rate_limiter
    @checkout_rate_limiter ||= RateLimiter.new(
      store: Rails.env.test? ? RateLimiter::MemoryStore.new : RateLimiter::RailsCacheStore.new,
      limit: 10,
      window: 60
    )
  end

  def create
    return if parse_payload!(allowed_fields: [ :address_id ]) == false
    require_payload_fields!(:address_id)
    require_string_field!(:address_id)
    invalid_payload_field!(:address_id) if @payload[:address_id].blank?
    idempotency_key = require_idempotency_key!
    check_checkout_rate_limit!

    order = CheckoutService.new.call(
      customer: current_customer,
      address_id: @payload[:address_id],
      idempotency_key: idempotency_key,
      actor_principal_id: Current.principal.user.id,
      request_id: Current.request_id
    )

    render_success data: OrderSerializer.as_json(order), status: :created
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    Current.principal&.user&.customer || raise(ActiveRecord::RecordNotFound)
  end

  def require_idempotency_key!
    key = request.headers["Idempotency-Key"].to_s
    return key if key.present? && key.bytesize <= 128

    invalid_payload_field!(:idempotency_key)
  end

  def check_checkout_rate_limit!
    limiter = self.class.checkout_rate_limiter
    keys = [
      "checkout:customer:#{current_customer.id}",
      "checkout:ip:#{request.remote_ip}"
    ]
    keys.each do |key|
      unless limiter.allowed?(key)
        @rate_limit_status = limiter.status(key)
        raise RateLimited
      end
    end
  end
end
