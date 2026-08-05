module Payments
  CreateCommand = Data.define(:order_id, :amount, :idempotency_key) do
    def initialize(order_id:, amount:, idempotency_key:)
      raise ArgumentError, "order_id is required" if order_id.blank?
      raise ArgumentError, "amount must be Money" unless amount.is_a?(Money)
      raise ArgumentError, "idempotency_key is required" if idempotency_key.blank?

      super
    end
  end
end
