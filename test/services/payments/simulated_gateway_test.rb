require "test_helper"

class Payments::SimulatedGatewayTest < ActiveSupport::TestCase
  test "abstract gateway requires an adapter implementation" do
    assert_raises(NotImplementedError) { Payments::Gateway.new.create(nil) }
  end

  test "implements provider-neutral contract with authoritative pending intent" do
    command = Payments::CreateCommand.new(
      order_id: ApplicationId.generate,
      amount: Money.new(cents: 1_500, currency: "BRL"),
      idempotency_key: "checkout-key"
    )

    intent = Payments::SimulatedGateway.new.create(command)

    assert_instance_of Payments::Intent, intent
    assert_equal "pending", intent.state
    assert_equal "simulated", intent.provider
    assert_equal "simulated", intent.method
    assert_equal 1_500, intent.amount.cents
    assert_equal "BRL", intent.amount.currency
    assert_match(/\Asim_/, intent.external_reference)
  end

  test "same command returns same external reference" do
    command = Payments::CreateCommand.new(
      order_id: ApplicationId.generate,
      amount: Money.new(cents: 500, currency: "BRL"),
      idempotency_key: "same-key"
    )
    gateway = Payments::SimulatedGateway.new

    assert_equal gateway.create(command).external_reference, gateway.create(command).external_reference
  end

  test "provider failure is translated to a stable recoverable error" do
    gateway = Payments::SimulatedGateway.new(failure: :unavailable)
    command = Payments::CreateCommand.new(
      order_id: ApplicationId.generate,
      amount: Money.new(cents: 500, currency: "BRL"),
      idempotency_key: "failure-key"
    )

    error = assert_raises(DomainError) { gateway.create(command) }
    assert_equal "external_dependency_unavailable", error.code
    assert_equal :service_unavailable, error.http_status
  end
end
