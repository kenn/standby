require 'spec_helper'

describe Slavery do
  def on_slave?
    Thread.current[:on_slave]
  end

  it 'sets thread local' do
    Slavery.on_slave { on_slave?.should == true }
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

  # it 'disables in transaction' do
  #   ActiveRecord::Base.transaction do
  #     expect { ActiveRecord::Base.slaveryable? }.to raise_error(Slavery::Error)
  #   end
  # end

  it 'disables by configuration' do
    Slavery.stub(:disabled).and_return(false)
    Slavery.on_slave { ActiveRecord::Base.slaveryable?.should == true }

    Slavery.stub(:disabled).and_return(true)
    Slavery.on_slave { ActiveRecord::Base.slaveryable?.should == false }
  end
end
