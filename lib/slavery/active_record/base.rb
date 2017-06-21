module ActiveRecord
  class Base
    class << self
      alias_method :connection_without_slavery, :connection

      def connection
        case Thread.current[:slavery]
        when :slave
          Slavery.connection_holder.connection_without_slavery
        when :master, NilClass
          connection_without_slavery
        else
          raise Slavery::Error.new("invalid target: #{Thread.current[:slavery]}")
        end
      end

      # Generate scope at top level e.g. User.on_slave
      def on_slave(slave_name = "slave")
        # Why where(nil)?
        # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
        context = where(nil)
        context.slavery_target = :slave
        context.slave_name = slave_name
        context
      end
    end
  end
end
