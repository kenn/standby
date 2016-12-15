module Slavery
  class Transaction
    class << self
      def base_depth
        @base_depth ||= begin
          testcase = ActiveSupport::TestCase
          if defined?(testcase) &&
              testcase.respond_to?(:use_transactional_fixtures) &&
              testcase.try(:use_transactional_fixtures)
            1
          else
            0
          end
        end
      end
    end
  end
end
