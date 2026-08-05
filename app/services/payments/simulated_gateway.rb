module Payments
  class SimulatedGateway < Gateway
    def initialize(failure: nil)
      @failure = failure
    end

    def create(command)
      raise unavailable_error if @failure

      reference_digest = Digest::SHA256.hexdigest("#{command.order_id}:#{command.idempotency_key}")
      Intent.new(
        state: "pending",
        provider: "simulated",
        method: "simulated",
        external_reference: "sim_#{reference_digest.first(32)}",
        amount: command.amount
      )
    end

    private

    def unavailable_error
      DomainError.new(code: :external_dependency_unavailable, http_status: :service_unavailable)
    end
  end
end
