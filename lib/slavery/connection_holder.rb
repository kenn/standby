module Slavery
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target = nil)
        spec = ActiveRecord::Base.configurations[Slavery.spec_key_for(target)]
        raise Error.new("Slavery.spec_key or assigned slave target '#{target}' is invalid!") if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder(target)
      klass_name = "Slavery#{target.to_s.camelize}ConnectionHolder"
      slave_connections[klass_name] ||= begin
        klass = Class.new(Slavery::ConnectionHolder) do
          self.abstract_class = true
        end
        Object.const_set(klass_name, klass)
        klass.activate(target)
        klass
      end
    end
  end
end
