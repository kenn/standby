module Slavery
  class SlaveConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate
        raise Error.new('Slavery.spec_key invalid!') unless ActiveRecord::Base.configurations[Slavery.spec_key]
        establish_connection Slavery.spec_key.to_sym
      end
    end
  end
end
