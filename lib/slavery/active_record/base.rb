module ActiveRecord
  class Base
    class << self
      alias_method :connection_without_slavery, :connection

      def connection
        case Thread.current[:slavery]
        when :master, NilClass
          connection_without_slavery
        else
          Slavery.connection_holder(Thread.current[:slavery]).connection_without_slavery
        end
      end

      # Generate scope at top level e.g. User.on_slave
      def on_slave(name = :null_state)
        # Why where(nil)?
        # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
        context = where(nil)
        context.slavery_target = name || :null_state
        context
      end
    end
  end
end
