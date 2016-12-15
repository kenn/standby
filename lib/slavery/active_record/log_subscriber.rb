module ActiveRecord
  class LogSubscriber

    alias_method :debug_without_slavery, :debug

    def debug(msg)
      db = Slavery.disabled ? "" : color("[#{Thread.current[:slavery] || "master"}]", ActiveSupport::LogSubscriber::GREEN, true)
      debug_without_slavery(db + msg)
    end

  end
end
