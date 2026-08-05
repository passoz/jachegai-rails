require "test_helper"

class IdempotencyServiceTest < ActiveSupport::TestCase
  setup do
    @principal_id = ApplicationId.generate
    @resource = Seller.create!(name: "Idempotent Resource", moderation_state: "approved")
  end

  test "same key and canonical payload returns original resource without executing twice" do
    executions = 0
    first = IdempotencyService.execute(
      principal_id: @principal_id, operation: "checkout", key: "same-key", payload: { address_id: "a", options: { b: 2, a: 1 } }
    ) do |record|
      executions += 1
      IdempotencyService.complete!(record, resource: @resource, response_status: 201)
      @resource
    end

    second = IdempotencyService.execute(
      principal_id: @principal_id, operation: "checkout", key: "same-key", payload: { options: { a: 1, b: 2 }, address_id: "a" }
    ) { executions += 1 }

    assert_equal @resource.id, first.id
    assert_equal @resource.id, second.id
    assert_equal 1, executions
  end

  test "same key with a different payload conflicts" do
    IdempotencyService.execute(
      principal_id: @principal_id, operation: "checkout", key: "key", payload: { address_id: "a" }
    ) do |record|
      IdempotencyService.complete!(record, resource: @resource, response_status: 201)
      @resource
    end

    error = assert_raises(DomainError) do
      IdempotencyService.execute(
        principal_id: @principal_id, operation: "checkout", key: "key", payload: { address_id: "b" }
      ) { flunk "must not execute" }
    end

    assert_equal "idempotency_conflict", error.code
    assert_equal "payload_mismatch", error.as_json.dig(:context, :reason)
  end

  test "processing claim conflicts until stale and failed claim can retry" do
    record = IdempotencyRecord.create!(
      principal_id: @principal_id, operation: "checkout", key: "processing",
      request_digest: IdempotencyService.digest({ address_id: "a" }), state: "processing", locked_at: Time.current
    )

    error = assert_raises(DomainError) do
      IdempotencyService.execute(
        principal_id: @principal_id, operation: "checkout", key: "processing", payload: { address_id: "a" }
      ) { flunk }
    end
    assert_equal "in_progress", error.as_json.dig(:context, :reason)

    record.update_columns(state: "failed", last_error_code: "external_dependency_unavailable")
    executed = false
    IdempotencyService.execute(
      principal_id: @principal_id, operation: "checkout", key: "processing", payload: { address_id: "a" }
    ) do |claimed|
      executed = true
      IdempotencyService.complete!(claimed, resource: @resource, response_status: 201)
      @resource
    end

    assert executed
    assert_equal "completed", record.reload.state
  end
end
