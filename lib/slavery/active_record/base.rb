module ActiveRecord
  class Base
    class << self
      alias_method :connection_without_slavery, :connection

      def connection
        case Thread.current[:slavery]
        when :master, NilClass
          connection_without_slavery
        else
          Slavery.connection_holder.connection_without_slavery
        end
      end

      # Generate scope at top level e.g. User.on_slave
      def on_slave(connection_name = nil)
        # Why where(nil)?
        # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
        context = where(nil)
        context.slavery_target = connection_name.presence || :slave # Handle explicit nil or blank
        context
      end
    end
  end
end
