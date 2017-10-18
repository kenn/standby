module Slavery
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target)
        spec = ActiveRecord::Base.configurations["#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"]
        raise Error.new("Slave target '#{target}' is invalid!") if spec.nil?
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
