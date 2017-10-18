require 'active_record'
require 'slavery/version'
require 'slavery/base'
require 'slavery/error'
require 'slavery/connection_holder'
require 'slavery/transaction'
require 'slavery/active_record/base'
require 'slavery/active_record/connection_handling'
require 'slavery/active_record/relation'
require 'slavery/active_record/log_subscriber'

module Slavery
  class << self
    attr_accessor :disabled

    def slave_connections
      @slave_connections ||= {}
    end

    def on_slave(name = :null_state, &block)
      raise Slavery::Error.new('invalid slave target') unless name.is_a?(Symbol)
      Base.new(name).run &block
    end

    def on_master(&block)
      Base.new(:master).run &block
    end
  end
end
