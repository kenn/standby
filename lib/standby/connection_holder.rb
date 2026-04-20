module Standby
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target)
        env_name = "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"
        # Rails 6.1+ exposes DatabaseConfigurations helpers; older versions still use hash access.
        if ActiveRecord::Base.configurations.respond_to?(:find_db_config)
          spec = ActiveRecord::Base.configurations.find_db_config(env_name)&.configuration_hash
        else
          spec = ActiveRecord::Base.configurations[env_name]
        end
        raise Error, "Standby target '#{target}' is invalid!" if spec.nil?

        establish_connection spec
      end
    end
  end

  class << self
    def connection_holder(target)
      klass_name = "Standby#{target.to_s.camelize}ConnectionHolder"
      standby_connections[klass_name] || standby_connections_mutex.synchronize do
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
end
