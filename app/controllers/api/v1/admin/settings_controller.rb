class Api::V1::Admin::SettingsController < Api::V1::BaseController
  before_action :require_admin!

  def index
    authorize!(MarketplaceSetting, action: :index)
    scope = MarketplaceSetting.order(effective_at: :desc, created_at: :desc)
    pagination = paginate(scope)

    render_success(
      data: pagination.records.map { |setting| serialize_setting(setting) },
      meta: pagination.meta
    )
  end

  def create
    return unless parse_payload!(allowed_fields: [ :key, :value, :reason, :effective_at ])
    require_string_field!(:key)
    require_string_field!(:value)

    authorize!(MarketplaceSetting, action: :create)

    effective_at = if @payload[:effective_at].present?
      Time.iso8601(@payload[:effective_at])
    else
      Time.current
    end

    setting = MarketplaceSetting.transaction do
      created = MarketplaceSetting.set!(
        key: @payload[:key],
        value: @payload[:value],
        actor: Current.principal&.user || current_user,
        effective_at: effective_at,
        reason: @payload[:reason]
      )

      AuditRecord.record!(
        actor: Current.principal&.user || current_user,
        action: "update_marketplace_setting",
        resource_type: "MarketplaceSetting",
        resource_id: created.id,
        result: "success",
        reason: @payload[:reason],
        request_id: Current.request_id,
        metadata: { key: @payload[:key], value: @payload[:value] }.to_json
      )

      created
    end

    render_success(data: serialize_setting(setting), status: :created)
  end

  private

  def serialize_setting(setting)
    {
      id: setting.id,
      key: setting.key,
      value: setting.value,
      effective_at: setting.effective_at.iso8601,
      actor_id: setting.actor_id,
      reason: setting.reason,
      created_at: setting.created_at.iso8601
    }
  end
end
