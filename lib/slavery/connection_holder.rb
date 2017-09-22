module Slavery
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate
        spec = ActiveRecord::Base.configurations[Slavery.spec_key]
        raise Error.new('Slavery.spec_key invalid!') if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder
      slave_connections[Slavery.spec_key] ||= begin
        klass = Class.new(Slavery::ConnectionHolder) do
          self.abstract_class = true
        end
        klass_name = "SlaveryConnection#{Slavery.spec_key.camelize}"
        Object.const_set(klass_name, klass) unless Object.const_defined?(klass_name)
        klass.activate
        klass
      end
    end
  end
end
