class Api::V1::Admin::UsersController < Api::V1::BaseController
  before_action :require_admin!
  before_action :set_user, only: [ :show, :disable, :enable ]

  def index
    authorize!(User, action: :index)
    scope = User.includes(:role_assignments, :customer, :seller_memberships, :courier).order(created_at: :desc, id: :desc)
    pagination = paginate(scope)

    render_success(
      data: pagination.records.map { |user| serialize_user(user) },
      meta: pagination.meta
    )
  end

  def show
    authorize!(@user, action: :show)
    render_success(data: serialize_user(@user))
  end

  def disable
    authorize!(@user, action: :disable)
    User.transaction do
      @user.disable!

      AuditRecord.record!(
        actor: Current.principal&.user || current_user,
        action: "disable_user",
        resource_type: "User",
        resource_id: @user.id,
        result: "success",
        request_id: Current.request_id
      )
    end

    render_success(data: serialize_user(@user.reload))
  end

  def enable
    authorize!(@user, action: :enable)
    User.transaction do
      @user.enable!

      AuditRecord.record!(
        actor: Current.principal&.user || current_user,
        action: "enable_user",
        resource_type: "User",
        resource_id: @user.id,
        result: "success",
        request_id: Current.request_id
      )
    end

    render_success(data: serialize_user(@user.reload))
  end

  private

  def set_user
    @user = User.includes(:role_assignments, :customer, :seller_memberships, :courier).find(params[:id])
  end

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      disabled_at: user.disabled_at&.iso8601,
      roles: user.roles,
      customer_id: user.customer&.id,
      courier_id: user.courier&.id,
      seller_ids: user.seller_memberships.map(&:seller_id),
      created_at: user.created_at.iso8601,
      updated_at: user.updated_at.iso8601
    }
  end
end
