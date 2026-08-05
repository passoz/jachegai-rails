require "test_helper"

class Api::V1::Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = User.create!(
      email: "admin-users@example.com",
      password: "password123",
      full_name: "Admin User"
    )
    RoleAssignment.create!(user: @admin_user, role: "admin")

    @normal_user = User.create!(
      email: "customer-users@example.com",
      password: "password123",
      full_name: "Customer User"
    )
    RoleAssignment.create!(user: @normal_user, role: "customer")

    @admin_token = Session.issue_for(@admin_user)
    @user_token = Session.issue_for(@normal_user)
  end

  test "admin can list users" do
    get "/api/v1/admin/users", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert json["data"].is_a?(Array)
    user_emails = json["data"].map { |u| u["email"] }
    assert_includes user_emails, "admin-users@example.com"
    assert_includes user_emails, "customer-users@example.com"
  end

  test "admin can show user detail" do
    get "/api/v1/admin/users/#{@normal_user.id}", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal @normal_user.id, json["data"]["id"]
    assert_equal "customer-users@example.com", json["data"]["email"]
    assert_includes json["data"]["roles"], "customer"
  end

  test "admin can disable user revoking active sessions" do
    user_session_token = Session.issue_for(@normal_user)
    raw_session = Session.find_by_token(user_session_token)
    assert_nil raw_session.revoked_at

    post "/api/v1/admin/users/#{@normal_user.id}/disable", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]

    @normal_user.reload
    assert @normal_user.disabled?

    raw_session.reload
    assert raw_session.revoked_at.present?

    # Trying to use normal user token now fails
    get "/api/v1/customer/profile", headers: { "Authorization" => "Bearer #{user_session_token}" }
    assert_response :unauthorized
  end

  test "admin can enable disabled user without reactivating old sessions" do
    @normal_user.update!(disabled_at: Time.current)
    old_token = Session.issue_for(@normal_user)
    old_session = Session.find_by_token(old_token)
    old_session.revoke!

    post "/api/v1/admin/users/#{@normal_user.id}/enable", headers: { "Authorization" => "Bearer #{@admin_token}" }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["ok"]

    @normal_user.reload
    refute @normal_user.disabled?

    old_session.reload
    assert old_session.revoked_at.present?, "old session must remain revoked"
  end

  test "non-admin receives 403 forbidden" do
    get "/api/v1/admin/users", headers: { "Authorization" => "Bearer #{@user_token}" }
    assert_response :forbidden

    get "/api/v1/admin/users/#{@normal_user.id}", headers: { "Authorization" => "Bearer #{@user_token}" }
    assert_response :forbidden

    post "/api/v1/admin/users/#{@normal_user.id}/disable", headers: { "Authorization" => "Bearer #{@user_token}" }
    assert_response :forbidden

    post "/api/v1/admin/users/#{@normal_user.id}/enable", headers: { "Authorization" => "Bearer #{@user_token}" }
    assert_response :forbidden
  end
end
