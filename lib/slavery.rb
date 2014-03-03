require 'slavery/version'
require 'slavery/railtie'
require 'active_record'
require 'active_support/core_ext/module/attribute_accessors'

module Slavery
  extend ActiveSupport::Concern

  included do
    require 'slavery/relation'

    class << self
      alias_method_chain :connection, :slavery
    end
  end

  class Error < StandardError; end

  mattr_accessor :disabled
  mattr_accessor :slave_spec_name

  class << self
    def slave_spec_name
      if @@slave_spec_name.nil?
        @@slave_spec_name = "#{Slavery.env}_slave"
      elsif @@slave_spec_name && @@slave_spec_name.kind_of?(Proc)
        @@slave_spec_name = @@slave_spec_name.call
      end

      @@slave_spec_name
    end

    def on_slave(&block)
      run true, &block
    end

    def on_master(&block)
      run false, &block
    end

    def run(new_value)
      old_value = Thread.current[:on_slave] # Save for recursive nested calls
      Thread.current[:on_slave] = new_value
      yield
    ensure
      Thread.current[:on_slave] = old_value
    end

    def env
      self.env = defined?(Rails) ? Rails.env.to_s : 'development' unless @env
      @env
    end

    def env=(string)
      @env = ActiveSupport::StringInquirer.new(string)
    end
  end

  module ClassMethods
    def on_slave
      # Why where(nil)?
      # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
      context = where(nil)
      context.slavery_target = :slave
      context
    end

    def connection_with_slavery
      if Thread.current[:on_slave] and slaveryable?
        slave_connection
      else
        master_connection
      end
    end

    def slaveryable?
      base_transaction_depth = defined?(ActiveSupport::TestCase) &&
        ActiveSupport::TestCase.respond_to?(:use_transactional_fixtures) &&
        ActiveSupport::TestCase.try(:use_transactional_fixtures) ? 1 : 0
      inside_transaction = master_connection.open_transactions > base_transaction_depth
      raise Error.new('on_slave cannot be used inside transaction block!') if inside_transaction

      !Slavery.disabled
    end

    def master_connection
      connection_without_slavery
    end

    def slave_connection
      slave_connection_holder.connection_without_slavery
    end

    # Create an anonymous AR class to hold slave connection
    def slave_connection_holder
      @slave_connection_holder ||= Class.new(ActiveRecord::Base) {
        self.abstract_class = true

        def self.name
          "SlaveConnectionHolder"
        end

        spec = [Slavery.slave_spec_name, Slavery.env].find do |spec|
          ActiveRecord::Base.configurations[spec]
        end or raise Error.new("#{Slavery.slave_spec_name} or #{Slavery.env} must exist!")

        establish_connection spec
      }
    end
  end
end
