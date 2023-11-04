require 'standby/version'

module ActiveRecord
  class LogSubscriber

    alias_method :debug_without_standby, :debug

    def debug(msg)
      db = Standby.disabled ? '' : log_header
      debug_without_standby(db + msg)
    end

    def log_header
      if Standby.version_gte?('7.1')
        color("[#{Thread.current[:_standby] || "primary"}]", ActiveSupport::LogSubscriber::GREEN, bold: true)
      else
        color("[#{Thread.current[:_standby] || "primary"}]", ActiveSupport::LogSubscriber::GREEN, true)
      end
    end
  end
end
