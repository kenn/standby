require 'active_record'
require 'standby/version'
require 'standby/base'
require 'standby/error'
require 'standby/connection_holder'
require 'standby/transaction'
require 'standby/active_record/base'
require 'standby/active_record/connection_handling'
require 'standby/active_record/relation'
require 'standby/active_record/log_subscriber'

module Standby
  class << self
    attr_accessor :disabled

    def standby_connections
      @standby_connections ||= {}
    end

    def on_standby(name = :null_state, &block)
      raise Standby::Error.new('invalid standby target') unless name.is_a?(Symbol)
      Base.new(name).run &block
    end

    def on_primary(&block)
      Base.new(:primary).run &block
    end
  end
end
