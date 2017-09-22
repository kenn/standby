module Slavery
  class Base
    def initialize(target,spec_key = nil)
      @spec_key = spec_key
      @target = decide_with(target)
    end

    def run(&block)
      run_on(@target, @spec_key, &block)
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

    def run_on(target,spec_key = nil)
      backup = Thread.current[:slavery] # Save for recursive nested calls
      spec_key_backup = Thread.current[:slavery_spec]
      Thread.current[:slavery] = target
      Thread.current[:slavery_spec] = spec_key
      yield
    ensure
      Thread.current[:slavery] = backup
      Thread.current[:slavery_spec] = spec_key_backup
    end
  end
end
