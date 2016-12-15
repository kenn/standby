module Slavery
  class SlaveConnectionHolder < ActiveRecord::Base
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
end
