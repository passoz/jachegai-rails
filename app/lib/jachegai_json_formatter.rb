class JachegaiJsonFormatter < ::Logger::Formatter
  def call(severity, time, progname, message)
    payload = message.is_a?(Hash) ? message : { message: message.to_s }
    JSON.generate(payload.merge(severity: severity, timestamp: time.utc.iso8601, progname: progname).compact) + "\n"
  end
end
