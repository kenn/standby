require 'spec_helper'

describe Slavery do
  def slavery_value
    Thread.current[:slavery]
  end

  def on_slave?
    slavery_value == :slave
  end

  it 'sets thread local' do
    Slavery.on_master { expect(slavery_value).to be :master }
    Slavery.on_slave  { expect(slavery_value).to be :slave }
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

  it 'raises error in transaction' do
    User.transaction do
      expect { Slavery.on_slave { User.first } }.to raise_error(Slavery::Error)
    end
  end

  it 'disables by configuration' do
    backup = Slavery.disabled

    Slavery.disabled = false
    Slavery.on_slave { expect(slavery_value).to be :slave }

    Slavery.disabled = true
    Slavery.on_slave { expect(slavery_value).to be :master }

    Slavery.disabled = backup
  end

  it 'sets the Slavery database spec name by configuration' do
    Slavery.spec_key = 'custom_slave'
    expect(Slavery.spec_key).to eq 'custom_slave'
  end

  it 'avoids stack overflow with 3rdparty gem that defines alias_method. namely newrelic...' do
    class ActiveRecord::Relation
      alias_method :calculate_without_thirdparty, :calculate

      def calculate(*args)
        calculate_without_thirdparty(*args)
      end
    end

    expect(User.count).to be 2

    class ActiveRecord::Relation
      alias_method :calculate, :calculate_without_thirdparty
    end
  end

  it 'works with any scopes' do
    expect(User.count).to be 2
    expect(User.on_slave.count).to be 1

    # Why where(nil)?
    # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
    expect(User.where(nil).to_a.size).to be 2
    expect(User.on_slave.where(nil).to_a.size).to be 1
  end
end
