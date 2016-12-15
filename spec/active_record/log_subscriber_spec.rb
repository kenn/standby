require 'spec_helper'
require 'logger'

describe ActiveRecord::LogSubscriber do

  describe 'logging' do

    let(:log) { StringIO.new }
    let(:logger) { Logger.new(log) }

    before do
      ActiveRecord::Base.logger = logger
    end

    after do
      Slavery.disabled = false
    end

    it 'it prefixes log messages with master' do
      User.count
      log.rewind
      expect(log.read).to include('[DB: master]')
    end

    it 'it prefixes log messages with the slave connection' do
      User.on_slave.count
      log.rewind
      expect(log.read).to include('[DB: slave]')
    end

    it 'it does nothing when slavery is disabled' do
      Slavery.disabled = true
      User.count
      log.rewind
      expect(log.read).to_not include('[DB: master]')
    end

  end

end
