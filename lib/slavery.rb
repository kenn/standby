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
    attr_accessor :spec_key

    def spec_key_for(target = nil)
      spec = spec_key if target.nil? || target.to_s == "slave" # Support for Slavery.spec_key= 
      spec || "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"
    end

    def slave_connections
      @slave_connections ||= {}
    end

    def on_slave(name = nil, &block)
      Base.new(name).run &block
    end

    def on_master(&block)
      Base.new(:master).run &block
    end
  end
end
