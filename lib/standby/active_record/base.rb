module ActiveRecord
  class Base
    class << self
      alias_method :connection_without_standby, :connection

      def connection
        case Thread.current[:_standby]
        when :primary, NilClass
          connection_without_standby
        else
          Standby.connection_holder(Thread.current[:_standby]).connection_without_standby
        end
      end

      # Generate scope at top level e.g. User.on_standby
      def on_standby(name = :null_state)
        # Why where(nil)?
        # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
        context = where(nil)
        context.standby_target = name || :null_state
        context
      end
    end
  end
end
