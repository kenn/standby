require 'spec_helper'

describe 'configuration' do
  before do
    # Backup connection and configs
    @backup_conn = Slavery.instance_variable_get :@slave_pools
    @backup_config = ActiveRecord::Base.configurations.dup
    @backup_disabled = Slavery.disabled
    Slavery.instance_variable_set :@slave_pools, {}
  end

  after do
    # Restore connection and configs
    Slavery.instance_variable_set :@slave_pools, @backup_conn
    ActiveRecord::Base.configurations = @backup_config
    Slavery.disabled = @backup_disabled
  end

  it 'raises error if slave configuration not specified' do
    ActiveRecord::Base.configurations['test_slave'] = nil

    expect { Slavery.on_slave { User.count } }.to raise_error(Slavery::Error)
  end

  it 'connects to master if slave configuration not specified' do
    ActiveRecord::Base.configurations['test_slave'] = nil
    Slavery.disabled = true

    expect(Slavery.on_slave { User.count }).to be 2
  end

  it 'connects to slave when specified as a hash' do
    Slavery.spec_key = 'test_slave'
    hash = ActiveRecord::Base.configurations['test_slave']
    expect(Slavery::ConnectionHolder).to receive(:establish_connection).with(hash)
    Slavery::ConnectionHolder.activate
  end

  it 'connects to slave when specified as a url' do
    expected = if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.1.0')
      'postgres://root:@localhost:5432/test_slave'
    else
      {
        'adapter'  => 'postgresql',
        'username' => 'root',
        'host'     => 'localhost',
        'port'     => 5432,
        'database' => 'test_slave'
      }
    end
    Slavery.spec_key = 'test_slave_url'
    expect(Slavery::ConnectionHolder).to receive(:establish_connection).with(expected)
    Slavery::ConnectionHolder.activate
  end
end
