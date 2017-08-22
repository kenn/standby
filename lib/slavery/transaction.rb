module Slavery
  class Transaction
    # The methods on ActiveSupport::TestCase which can potentially be used
    # to determine if transactional fixtures are enabled
    TEST_CONFIG_METHODS = [
      :use_transactional_tests,
      :use_transactional_fixtures
    ]

    class << self
      def base_depth
        @base_depth ||= if defined?(ActiveSupport::TestCase) &&
          TEST_CONFIG_METHODS.any? { |m| ActiveSupport::TestCase.try(m) }
        then
          1
        else
          0
        end
      end
    end
  end
end
