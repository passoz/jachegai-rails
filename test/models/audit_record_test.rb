require "test_helper"

class AuditRecordTest < ActiveSupport::TestCase
  test "record! creates an immutable audit entry" do
    actor = User.create!(email: "admin-audit@example.com", password: "password123", full_name: "Admin")
    seller = Seller.create!(name: "Loja Auditada")

    record = AuditRecord.record!(
      actor: actor,
      action: "approve",
      resource_type: "Seller",
      resource_id: seller.id,
      result: "success",
      reason: "aprovado após verificação",
      correlation_id: "req-123"
    )

    assert record.id.present?
    assert_equal actor.id, record.actor_principal_id
    assert_equal "approve", record.action
    assert_equal seller.id, record.resource_id
    assert_equal "req-123", record.correlation_id
  end

  test "persisted audit records are append-only" do
    actor = User.create!(email: "admin-audit2@example.com", password: "password123", full_name: "Admin2")
    seller = Seller.create!(name: "Loja Imutável")
    record = AuditRecord.record!(actor: actor, action: "suspend", resource_type: "Seller", resource_id: seller.id)

    assert_raises(ActiveRecord::ReadOnlyRecord) { record.update!(result: "failure") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { record.destroy! }
    assert AuditRecord.find(record.id).present?
  end

  test "record! accepts request_id parameter and responds to request_id getter" do
    actor = User.create!(email: "admin-audit-req@example.com", password: "password123", full_name: "Admin Req")
    seller = Seller.create!(name: "Loja Req")

    record = AuditRecord.record!(
      actor: actor,
      action: "approve",
      resource_type: "Seller",
      resource_id: seller.id,
      request_id: "req-xyz-999"
    )

    assert_equal "req-xyz-999", record.request_id
    assert_equal "req-xyz-999", record.correlation_id
  end

  test "record! requires actor, action, resource and result" do
    assert_raises(ActiveRecord::RecordInvalid) do
      AuditRecord.record!(actor: nil, action: nil, resource_type: nil, resource_id: nil)
    end
  end
end
