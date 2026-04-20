require 'spec_helper'

describe 'configuration' do
  before do
    # Backup connection and configs
    @backup_conn = (Standby.instance_variable_get(:@standby_connections) || {}).dup
    # Rails 6.1+ wraps configurations in ActiveRecord::DatabaseConfigurations.
    if ActiveRecord::Base.configurations.respond_to?(:configs_for)
      @backup_config = ActiveRecord::Base.configurations.configs_for.map do |config|
        [config.env_name, config.configuration_hash]
      end.to_h
    else
      @backup_config = ActiveRecord::Base.configurations.dup
    end
    @backup_disabled = Standby.disabled
    @backup_conn.each_key do |klass_name|
      Object.send(:remove_const, klass_name) if Object.const_defined?(klass_name)
    end
    Standby.instance_variable_set :@standby_connections, {}
  end

  after do
    # Restore connection and configs
    Standby.instance_variable_set :@standby_connections, @backup_conn
    ActiveRecord::Base.configurations = @backup_config
    Standby.disabled = @backup_disabled
  end

  it 'raises error if standby configuration not specified' do
    # Rails 6.1+ no longer supports mutating configurations via hash-style access.
    if ActiveRecord::Base.configurations.respond_to?(:configs_for)
      ActiveRecord::Base.configurations = @backup_config.merge({ 'test_standby' => {} })
    else
      ActiveRecord::Base.configurations['test_standby'] = nil
    end

    expect { Standby.on_standby { User.count } }.to raise_error(Standby::Error)
  end

  it 'connects to primary if standby configuration is disabled' do
    # Rails 6.1+ no longer supports mutating configurations via hash-style access.
    if ActiveRecord::Base.configurations.respond_to?(:configs_for)
      ActiveRecord::Base.configurations = @backup_config.merge({ 'test_standby' => {} })
    else
      ActiveRecord::Base.configurations['test_standby'] = nil
    end
    Standby.disabled = true

    expect(Standby.on_standby { User.count }).to be 2
  end

  it 'initializes a standby connection holder once under contention' do
    entered_activate = Queue.new
    release_activate = Queue.new
    call_count = 0

    allow(Standby::ConnectionHolder).to receive(:activate).and_wrap_original do |original, target|
      call_count += 1
      if call_count == 1
        entered_activate << true
        release_activate.pop
      end

      original.call(target)
    end

    t1 = Thread.new { Standby.connection_holder(:standby) }
    entered_activate.pop

    t2 = Thread.new { Standby.connection_holder(:standby) }

    expect(t2.join(0.1)).to be_nil
    expect(call_count).to eq(1)

    release_activate << true

    [t1, t2].each(&:join)

    expect(Standby.connection_holder(:standby).name).to eq('StandbyStandbyConnectionHolder')
    expect(call_count).to eq(1)
  end
end
