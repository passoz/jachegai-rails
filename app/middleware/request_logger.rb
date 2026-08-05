class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(2)
    Rails.logger.info(
      event: "request",
      method: env["REQUEST_METHOD"],
      path: env["PATH_INFO"],
      status: status,
      duration_ms: duration_ms,
      request_id: env["action_dispatch.request_id"]
    )
    [ status, headers, body ]
  rescue StandardError
    Rails.logger.error(
      event: "request_failed",
      method: env["REQUEST_METHOD"],
      path: env["PATH_INFO"],
      request_id: env["action_dispatch.request_id"]
    )
    raise
  end
end
