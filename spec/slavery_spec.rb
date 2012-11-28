require 'spec_helper'

describe Slavery do
  def on_slave?
    Thread.current[:on_slave]
  end

  it 'sets thread local' do
    Slavery.on_master { on_slave?.should == false }
    Slavery.on_slave  { on_slave?.should == true }
  end

  it 'returns value from block' do
    Slavery.on_master { User.count }.should == 2
    Slavery.on_slave  { User.count }.should == 1
  end

  it 'handles nested calls' do
    # Slave -> Slave
    Slavery.on_slave do
      on_slave?.should == true

      Slavery.on_slave do
        on_slave?.should == true
      end

      on_slave?.should == true
    end

    # Slave -> Master
    Slavery.on_slave do
      on_slave?.should == true

      Slavery.on_master do
        on_slave?.should == false
      end

      on_slave?.should == true
    end
  end

  it 'disables in transaction' do
    User.transaction do
      expect { User.slaveryable? }.to raise_error(Slavery::Error)
    end
  end

  it 'disables by configuration' do
    Slavery.stub(:disabled).and_return(false)
    Slavery.on_slave { User.slaveryable?.should == true }

    Slavery.stub(:disabled).and_return(true)
    Slavery.on_slave { User.slaveryable?.should == false }
  end

  it 'sets the Slavery database spec name by configuration' do
    Slavery.spec_key = "custom_slave"
    Slavery.spec_key.should eq 'custom_slave'

    Slavery.spec_key = lambda{
      "kewl_slave"
    }
    Slavery.spec_key.should eq "kewl_slave"

    Slavery.spec_key = lambda{
      "#{Slavery.env}_slave"
    }
    Slavery.spec_key.should eq "test_slave"
  end

  it 'works with scopes' do
    User.count.should == 2
    User.on_slave.count.should == 1

    # Why where(nil)?
    # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
    User.where(nil).to_a.size.should == 2
    User.on_slave.where(nil).to_a.size.should == 1
  end

  describe 'configuration' do
    before do
      # Backup connection and configs
      @old_conn = User.instance_variable_get :@slave_connection_holder
      @old_config = ActiveRecord::Base.configurations.dup
      User.instance_variable_set :@slave_connection_holder, nil
    end

    after do
      # Restore connection and configs
      User.instance_variable_set :@slave_connection_holder, @old_conn
      ActiveRecord::Base.configurations = @old_config
    end

    it 'connects to master if slave configuration not specified' do
      ActiveRecord::Base.configurations[Slavery.spec_key] = nil

      Slavery.on_slave { User.count }.should == 2
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
