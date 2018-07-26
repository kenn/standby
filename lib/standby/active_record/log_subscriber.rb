module ActiveRecord
  class LogSubscriber

    alias_method :debug_without_standby, :debug

    def debug(msg)
      db = Standby.disabled ? "" : color("[#{Thread.current[:_standby] || "primary"}]", ActiveSupport::LogSubscriber::GREEN, true)
      debug_without_standby(db + msg)
    end

  end
end
