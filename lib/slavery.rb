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
    attr_writer :spec_key

    def spec_key
      @spec_key ||= "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_slave"
    end

    def slave_connections
      @slave_connections ||= {}
    end

    def on_slave(name = nil, &block)
      if name.blank? || name.to_s == "slave"
        Base.new(:slave,spec_key).run &block
      else
        Base.new("slave_#{name}".to_sym,"#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_slave_#{name}").run &block
      end
    end

    def on_master(&block)
      Base.new(:master).run &block
    end
  end
end
