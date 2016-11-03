require 'spec_helper'

describe Slavery do
  def on_slave?
    Thread.current[:on_slave]
  end

  it 'sets thread local' do
    Slavery.on_master { expect(on_slave?).to be false }
    Slavery.on_slave  { expect(on_slave?).to be true }
  end

  it 'returns value from block' do
    expect(Slavery.on_master { User.count }).to be 2
    expect(Slavery.on_slave  { User.count }).to be 1
  end

  it 'handles nested calls' do
    # Slave -> Slave
    Slavery.on_slave do
      expect(on_slave?).to be true

      Slavery.on_slave do
        expect(on_slave?).to be true
      end

      expect(on_slave?).to be true
    end

    # Slave -> Master
    Slavery.on_slave do
      expect(on_slave?).to be true

      Slavery.on_master do
        expect(on_slave?).to be false
      end

      expect(on_slave?).to be true
    end
  end

  it 'disables in transaction' do
    User.transaction do
      expect { User.slaveryable? }.to raise_error(Slavery::Error)
    end
  end

  it 'disables by configuration' do
    allow(Slavery).to receive(:disabled).and_return(false)
    Slavery.on_slave { expect(User.slaveryable?).to be true }

    allow(Slavery).to receive(:disabled).and_return(true)
    Slavery.on_slave { expect(User.slaveryable?).to be false }
  end

  it 'sets the Slavery database spec name by configuration' do
    Slavery.spec_key = "custom_slave"
    expect(Slavery.spec_key).to eq 'custom_slave'

    Slavery.spec_key = lambda{
      "kewl_slave"
    }
    expect(Slavery.spec_key).to eq "kewl_slave"

    Slavery.spec_key = lambda{
      "#{Slavery.env}_slave"
    }
    expect(Slavery.spec_key).to eq "test_slave"
  end

  it 'works with scopes' do
    expect(User.count).to be 2
    expect(User.on_slave.count).to be 1

    # Why where(nil)?
    # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
    expect(User.where(nil).to_a.size).to be 2
    expect(User.on_slave.where(nil).to_a.size).to be 1
  end

  describe 'configuration' do
    before do
      # Backup connection and configs
      @old_conn = Thread.current[:slavery_connection]
      @old_config = ActiveRecord::Base.configurations.dup
      Thread.current[:slavery_connection] = nil
    end

    after do
      # Restore connection and configs
      Thread.current[:slavery_connection] = @old_conn
      ActiveRecord::Base.configurations = @old_config
    end

    it 'connects to master if slave configuration not specified' do
      ActiveRecord::Base.configurations[Slavery.spec_key] = nil

      expect(Slavery.on_slave { User.count }).to be 2
    end

    it 'raises error when no configuration found' do
      ActiveRecord::Base.configurations['test'] = nil
      ActiveRecord::Base.configurations[Slavery.spec_key] = nil

      expect { Slavery.on_slave { User.count } }.to raise_error(Slavery::Error)
    end
  end

  it "uses the same connection for all models" do
    Slavery.on_slave do
      User.connection.should == ActiveRecord::Base.connection
    end
  end
end
