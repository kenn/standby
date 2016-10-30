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

  mattr_accessor :env, :spec_key

  class << self
    attr_accessor :disabled

    def spec_key
      case @@spec_key
      when String   then @@spec_key
      when Proc     then @@spec_key = @@spec_key.call
      when NilClass then @@spec_key = "#{Slavery.env}_slave"
      end
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
      @@env ||= defined?(Rails) ? Rails.env.to_s : 'development'
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
      @base_transaction_depth ||= begin
        defined?(ActiveSupport::TestCase) &&
        ActiveSupport::TestCase.respond_to?(:use_transactional_fixtures) &&
        ActiveSupport::TestCase.try(:use_transactional_fixtures) ? 1 : 0
      end
      inside_transaction = master_connection.open_transactions > @base_transaction_depth
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

        spec = [Slavery.spec_key, Slavery.env].find do |spec_key|
          ActiveRecord::Base.configurations[spec_key]
        end or raise Error.new("#{Slavery.spec_key} or #{Slavery.env} must exist!")

        establish_connection spec.to_sym
      }
    end
  end
end
