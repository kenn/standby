require 'active_record'
require 'slavery/base'
require 'slavery/error'
require 'slavery/slave_connection_holder'
require 'slavery/version'
require 'slavery/active_record/base'
require 'slavery/active_record/connection_handling'
require 'slavery/active_record/relation'

module Slavery
  class << self
    attr_accessor :disabled
    attr_writer :spec_key

    def spec_key
      @spec_key ||= "#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_slave"
    end

    def on_slave(&block)
      Base.new(:slave).run &block
    end

    def on_master(&block)
      Base.new(:master).run &block
    end

    def slave_connection_holder
      @slave_connection_holder ||= begin
        SlaveConnectionHolder.activate
        SlaveConnectionHolder
      end
    end

    def base_transaction_depth
      @base_transaction_depth ||= begin
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
