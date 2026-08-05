class HealthController < ApplicationController
  skip_forgery_protection

  # Liveness: process is up — does NOT depend on the database.
  def liveness
    render json: {
      ok: true,
      data: {
        status: "alive",
        time: Time.now.utc.iso8601
      },
      meta: {}
    }, status: :ok
  end

  # Readiness: all mandatory dependencies are accessible.
  def readiness
    if database_ready?
      render json: {
        ok: true,
        data: {
          status: "ready",
          db: "ok",
          time: Time.now.utc.iso8601
        },
        meta: {}
      }, status: :ok
    else
      render json: {
        ok: false,
        error: {
          code: "service_unavailable",
          message: "Dependency unavailable"
        }
      }, status: :service_unavailable
    end
  end

  private

  def database_ready?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue ActiveRecord::ActiveRecordError, SQLite3::Exception
    false
  end
end
