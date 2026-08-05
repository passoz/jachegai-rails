require "test_helper"

class CourierModerationServiceTest < ActiveSupport::TestCase
  setup do
    @admin_user = User.create!(
      email: "admin.moderation@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Admin User"
    )
    @admin_user.role_assignments.create!(role: "admin")
    @admin_session = Session.issue_for(@admin_user, ip: "127.0.0.1", user_agent: "Test")
    @admin_principal = Principal.new(user: @admin_user, session: @admin_session)

    @courier_user = User.create!(
      email: "courier.mod@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Mod"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511977776666",
      document_number: "99988877766",
      vehicle_type: "motorcycle"
    )
  end

  test "admin approves pending courier and records audit" do
    service = CourierModerationService.new(@admin_principal)
    updated = service.approve!(@courier.id, reason: "Documents verified")

    assert_equal "approved", updated.moderation_state
    audit = AuditRecord.last
    assert_equal "courier.approve", audit.action
    assert_equal @courier.id, audit.resource_id
  end

  test "admin rejects pending courier" do
    service = CourierModerationService.new(@admin_principal)
    updated = service.reject!(@courier.id, reason: "Invalid license")

    assert_equal "rejected", updated.moderation_state
    assert_equal "offline", updated.operational_state
  end

  test "admin suspends approved courier and forces offline" do
    @courier.update!(moderation_state: "approved", operational_state: "available")
    service = CourierModerationService.new(@admin_principal)
    updated = service.suspend!(@courier.id, reason: "Safety violation")

    assert_equal "suspended", updated.moderation_state
    assert_equal "offline", updated.operational_state
  end

  test "admin reinstates suspended courier" do
    @courier.update!(moderation_state: "suspended", operational_state: "offline")
    service = CourierModerationService.new(@admin_principal)
    updated = service.reinstate!(@courier.id, reason: "Suspension expired")

    assert_equal "approved", updated.moderation_state
  end

  test "invalid moderation transition is rejected and audited as failure" do
    @courier.update!(moderation_state: "suspended")
    service = CourierModerationService.new(@admin_principal)

    error = assert_raises DomainError do
      service.approve!(@courier.id, reason: "Invalid retry", correlation_id: "moderation-conflict")
    end

    assert_equal "invalid_transition", error.code
    assert_equal :conflict, error.http_status
    assert_equal "suspended", @courier.reload.moderation_state
    audit = AuditRecord.find_by!(resource_type: "Courier", resource_id: @courier.id, action: "courier.approve")
    assert_equal "failure", audit.result
    assert_equal @admin_user.id, audit.actor_principal_id
    assert_equal "Invalid retry", audit.reason
    assert_equal "moderation-conflict", audit.correlation_id
    assert_equal({ "current_state" => "suspended", "target_state" => "approved" }, JSON.parse(audit.metadata))
  end

  test "audit persistence failure rolls moderation state back" do
    connection = ActiveRecord::Base.connection
    connection.execute(<<~SQL)
      CREATE TRIGGER abort_courier_audit
      BEFORE INSERT ON audit_records
      WHEN NEW.resource_type = 'Courier'
      BEGIN
        SELECT RAISE(ABORT, 'forced courier audit failure');
      END;
    SQL

    service = CourierModerationService.new(@admin_principal)
    assert_raises ActiveRecord::StatementInvalid do
      service.approve!(@courier.id, reason: "Documents verified")
    end

    assert_equal "pending_review", @courier.reload.moderation_state
    assert_empty AuditRecord.where(resource_type: "Courier", resource_id: @courier.id)
  ensure
    connection&.execute("DROP TRIGGER IF EXISTS abort_courier_audit")
  end
end
