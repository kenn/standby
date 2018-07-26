require 'spec_helper'
require 'logger'

describe ActiveRecord::LogSubscriber do

  describe 'logging' do

    let(:log) { StringIO.new }
    let(:logger) { Logger.new(log) }

    before do
      ActiveRecord::Base.logger = logger
      @backup_disabled = Standby.disabled
    end

    after do
      Standby.disabled = @backup_disabled
    end

    it 'it prefixes log messages with primary' do
      User.count
      log.rewind
      expect(log.read).to include('[primary]')
    end

    it 'it prefixes log messages with the standby connection' do
      User.on_standby.count
      log.rewind
      expect(log.read).to include('[standby]')
    end

    it 'it does nothing when standby is disabled' do
      Standby.disabled = true
      User.count
      log.rewind
      expect(log.read).to_not include('[primary]')
    end

  end

end
