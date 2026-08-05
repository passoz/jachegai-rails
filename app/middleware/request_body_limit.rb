class RequestBodyLimit
  DEFAULT_MAX_BYTES = StrictJson::DEFAULT_MAX_BYTES

  def initialize(app, max_bytes = DEFAULT_MAX_BYTES)
    @app = app
    @max_bytes = max_bytes
  end

  def call(env)
    length = env["CONTENT_LENGTH"].to_i
    return too_large if length > @max_bytes

    @app.call(env)
  end

  private

  def too_large
    body = {
      ok: false,
      error: {
        code: "payload_too_large",
        message: I18n.t("errors.messages.payload_too_large")
      }
    }.to_json
    [ 413, { "Content-Type" => "application/json", "Content-Length" => body.bytesize.to_s }, [ body ] ]
  end
end
