# Middleware that populates Current attributes for correlation.
class RequestContext
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    Current.request_id = request.request_id
    Current.user_agent = request.user_agent
    Current.remote_ip = request.remote_ip

    @app.call(env)
  ensure
    Current.reset
  end
end
