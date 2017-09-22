module Slavery
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(spec_key = nil)
        spec = ActiveRecord::Base.configurations[spec_key || Slavery.spec_key]
        raise Error.new('Slavery.spec_key invalid!') if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder(target,spec_key)
      slave_connections[spec_key] ||= begin
        klass = Class.new(Slavery::ConnectionHolder) do
          self.abstract_class = true
        end
        klass_name = "SlaveryConnection#{target.to_s.camelize}"
        Object.const_set(klass_name, klass) unless Object.const_defined?(klass_name)
        klass.activate(spec_key)
        klass
      end
    end
  end
end
