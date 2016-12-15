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
      @connection_holder ||= begin
        ConnectionHolder.activate
        ConnectionHolder
      end
    end
  end
end
