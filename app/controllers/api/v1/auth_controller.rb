class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate!, only: [ :register, :login ]
  before_action :validate_payload!, only: [ :register, :login ]

  # POST /api/v1/auth/register
  def register
    payload = @payload
    email = payload["email"].to_s.strip.downcase
    password = payload["password"].to_s
    full_name = payload["full_name"].to_s.strip

    user = User.new(email: email, password: password, full_name: full_name)
    unless user.valid?
      return render_error(
        code: "invalid_input",
        message: I18n.t("errors.messages.invalid_input"),
        status: :unprocessable_content,
        context: { fields: user.errors.to_hash }
      )
    end

    token = nil
    ActiveRecord::Base.transaction do
      user.save!
      RoleAssignment.create!(user: user, role: "customer")
      token = Session.issue_for(user, ip: request.remote_ip, user_agent: request.user_agent)
    end

    render json: {
      ok: true,
      data: { token: token, user: user_payload(user) },
      meta: {}
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(
      code: "invalid_input",
      message: I18n.t("errors.messages.invalid_input"),
      status: :unprocessable_content,
      context: { fields: e.record.errors.to_hash }
    )
  end

  # POST /api/v1/auth/login
  def login
    check_rate_limit!(
      rate_limit_key("login_ip"),
      rate_limit_key("login_identifier", identifier: @payload["email"])
    )

    result = SessionService.login(
      email: @payload["email"],
      password: @payload["password"],
      ip: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: {
      ok: true,
      data: { token: result[:token], user: user_payload(result[:user]) },
      meta: {}
    }, status: :ok
  rescue SessionService::AuthenticationError
    render_error(
      code: "unauthorized",
      message: I18n.t("errors.messages.unauthorized"),
      status: :unauthorized
    )
  end

  # GET /api/v1/auth/me
  def me
    render_success data: principal_payload
  end

  # POST /api/v1/auth/logout
  def logout
    token = bearer_token
    SessionService.logout(token) if token
    render_success data: { logged_out: true }
  end

  private

  def validate_payload!
    raw = request.raw_post
    parsed =
      begin
        StrictJson.parse(
          raw,
          allowed_fields: %i[email password full_name],
          content_type: request.content_type,
          max_bytes: StrictJson::DEFAULT_MAX_BYTES
        )
      rescue StrictJson::Error => e
        return render_error(
          code: e.code.to_s,
          message: I18n.t("errors.messages.#{e.code}", default: I18n.t("errors.messages.invalid_input")),
          status: e.http_status,
          context: { reason: e.code }
        )
      end

    if parsed["email"].blank? || parsed["password"].blank?
      return render_error(
        code: "invalid_input",
        message: I18n.t("errors.messages.invalid_input"),
        status: :unprocessable_content,
        context: { fields: { email: [ "is required" ], password: [ "is required" ] } }
      )
    end

    @payload = parsed
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      roles: user.roles.map(&:to_s)
    }
  end

  def principal_payload
    principal = Current.principal
    {
      id: principal.id,
      email: principal.user.email,
      full_name: principal.user.full_name,
      roles: principal.roles.map(&:to_s),
      active: principal.active?
    }
  end
end
