module Standby
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target)
        env_name = "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"
        spec = ActiveRecord::Base.configurations.configs_for(env_name: env_name).first&.configuration_hash
        raise Error.new("Standby target '#{target}' is invalid!") if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder(target)
      klass_name = "Standby#{target.to_s.camelize}ConnectionHolder"
      standby_connections[klass_name] ||= begin
        klass = Class.new(Standby::ConnectionHolder) do
          self.abstract_class = true
        end
        Object.const_set(klass_name, klass)
        klass.activate(target)
        klass
      end
    end
  end
end
