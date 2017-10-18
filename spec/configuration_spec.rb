require 'spec_helper'

describe 'configuration' do
  before do
    # Backup connection and configs
    @backup_conn = Slavery.instance_variable_get :@slave_connections
    @backup_config = ActiveRecord::Base.configurations.dup
    @backup_disabled = Slavery.disabled
    @backup_conn.each_key do |klass_name|
      Object.send(:remove_const, klass_name) if Object.const_defined?(klass_name)
    end
    Slavery.instance_variable_set :@slave_connections, {}
  end

  after do
    # Restore connection and configs
    Slavery.instance_variable_set :@slave_connections, @backup_conn
    ActiveRecord::Base.configurations = @backup_config
    Slavery.disabled = @backup_disabled
  end

  it 'raises error if slave configuration not specified' do
    ActiveRecord::Base.configurations['test_slave'] = nil

    expect { Slavery.on_slave { User.count } }.to raise_error(Slavery::Error)
  end

  it 'connects to master if slave configuration is disabled' do
    ActiveRecord::Base.configurations['test_slave'] = nil
    Slavery.disabled = true

    expect(Slavery.on_slave { User.count }).to be 2
  end
end
