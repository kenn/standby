module Standby
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target)
        env_name = "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"

        if ActiveRecord.version >= Gem::Version.new('6.0')
          spec = ActiveRecord::Base.configurations.find_db_config(env_name).try(:configuration_hash)
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