module Slavery
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target = nil)
        spec = ActiveRecord::Base.configurations[Slavery.spec_key_for(target)]
        raise Error.new('Slavery.spec_key invalid!') if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder(target)
      slave_connections[target] ||= begin
        klass = Class.new(Slavery::ConnectionHolder) do
          self.abstract_class = true
        end
        Object.const_set("SlaveryConnection#{target.to_s.camelize}", klass)
        klass.activate(target)
        klass
      end
    end
  end
end
