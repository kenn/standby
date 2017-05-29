module Slavery
  class Base
    def initialize(target)
      @target = decide_with(target)
    end

    def run(&block)
      run_on @target, &block
    end

  private

    def decide_with(target)
      if Slavery.disabled
        :master
      else
        raise Slavery::Error.new('on_slave cannot be used inside transaction block!') if inside_transaction?

        target
      end
    end

    def inside_transaction?
      open_transactions = run_on(:master) { ActiveRecord::Base.connection.open_transactions }
      open_transactions > Slavery::Transaction.base_depth
    end

    def run_on(target)
      backup = Thread.current[:slavery] # Save for recursive nested calls
      Thread.current[:slavery] = target
      yield
    ensure
      Thread.current[:slavery] = backup
    end
  end
end
