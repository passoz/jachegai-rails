require "test_helper"

class ModerationServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email: "admin-mod@example.com", password: "password123", full_name: "Admin")
    RoleAssignment.create!(user: @admin, role: "admin")
    @principal = Principal.new(user: @admin)
    @seller = Seller.create!(name: "Loja Moderação")
  end

  test "pending seller can be approved and audited" do
    seller = ModerationService.transition(seller: @seller, action: :approve, actor: @principal, reason: "docs ok", correlation_id: "corr-1")

    assert_equal "approved", seller.moderation_state
    assert seller.moderated_at.present?

    audit = AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).last
    assert_equal @admin.id, audit.actor_principal_id
    assert_equal "approve", audit.action
    assert_equal "success", audit.result
    assert_equal "docs ok", audit.reason
    assert_equal "corr-1", audit.correlation_id
  end

  test "all canonical transitions are audited" do
    transitions = [ :approve, :suspend, :reinstate ]
    transitions.each do |action|
      ModerationService.transition(seller: @seller, action: action, actor: @principal)
    end
    assert_equal "approved", @seller.reload.moderation_state
    assert_equal transitions.size, AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).count
  end

  test "invalid transition raises conflict and does not change state" do
    @seller.update!(moderation_state: "approved")
    error = assert_raises(DomainError) do
      ModerationService.transition(seller: @seller, action: :approve, actor: @principal)
    end
    assert_equal "invalid_transition", error.code
    assert_equal :conflict, error.http_status
    assert_equal "approved", @seller.reload.moderation_state
  end

  test "invalid transition is recorded as a failed audit entry" do
    @seller.update!(moderation_state: "approved")
    assert_raises(DomainError) do
      ModerationService.transition(seller: @seller, action: :approve, actor: @principal)
    end
    audit = AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).last
    assert_equal "failure", audit.result
    assert_equal "approve", audit.action
  end

  test "seller transition and successful audit are atomic" do
    original_record = AuditRecord.method(:record!)
    AuditRecord.define_singleton_method(:record!) { |**| raise ActiveRecord::RecordInvalid.new(AuditRecord.new) }

    assert_raises(ActiveRecord::RecordInvalid) do
      ModerationService.transition(seller: @seller, action: :approve, actor: @principal)
    end

    assert_equal "pending_review", @seller.reload.moderation_state
    assert_not @seller.moderated_at
    assert_equal 0, AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).count
  ensure
    AuditRecord.define_singleton_method(:record!, original_record)
  end

  test "non-admin actor cannot transition a seller" do
    customer = User.create!(email: "customer-mod@example.com", password: "password123", full_name: "Customer")
    RoleAssignment.create!(user: customer, role: "customer")

    error = assert_raises(DomainError) do
      ModerationService.transition(seller: @seller, action: :approve, actor: Principal.new(user: customer))
    end

    assert_equal "forbidden", error.code
    assert_equal "pending_review", @seller.reload.moderation_state
    assert_equal "failure", AuditRecord.where(resource_type: "Seller", resource_id: @seller.id).last.result
  end
end
