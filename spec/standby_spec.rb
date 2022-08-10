require 'spec_helper'

describe Standby do
  def standby_value
    Thread.current[:_standby]
  end

  def on_standby?
    standby_value == :standby
  end

  it 'sets thread local' do
    Standby.on_primary { expect(standby_value).to be :primary }
    Standby.on_standby { expect(standby_value).to be :standby }
    Standby.on_standby(:two) { expect(standby_value).to be :standby_two}
  end

  it 'returns value from block' do
    expect(Standby.on_primary { User.count }).to be 2
    expect(Standby.on_standby  { User.count }).to be 1
    expect(Standby.on_standby(:two) { User.count }).to be 0
  end

  it 'handles nested calls' do
    # Standby -> Standby
    Standby.on_standby do
      expect(on_standby?).to be true

      Standby.on_standby do
        expect(on_standby?).to be true
      end

      expect(on_standby?).to be true
    end

    # Standby -> Primary
    Standby.on_standby do
      expect(on_standby?).to be true

      Standby.on_primary do
        expect(on_standby?).to be false
      end

      expect(on_standby?).to be true
    end
  end

  it 'raises error in transaction' do
    User.transaction do
      expect { Standby.on_standby { User.first } }.to raise_error(Standby::Error)
    end
  end

  it 'disables by configuration' do
    backup = Standby.disabled

    Standby.disabled = false
    Standby.on_standby { expect(standby_value).to be :standby }

    Standby.disabled = true
    Standby.on_standby { expect(standby_value).to be :primary }

    Standby.disabled = backup
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

  it 'works with nils like standby' do
    expect(User.on_standby(nil).count).to be User.on_standby.count
  end

  it 'raises on blanks and strings' do
    expect { User.on_standby("").count }.to raise_error(Standby::Error)
    expect { User.on_standby("two").count }.to raise_error(Standby::Error)
    expect { User.on_standby("standby").count }.to raise_error(Standby::Error)
  end

  it 'raises with non existent extension' do
    expect { Standby.on_standby(:non_existent) { User.first } }.to raise_error(Standby::Error)
  end

  it 'works with any scopes' do
    expect(User.count).to be 2
    expect(User.on_standby(:two).count).to be 0
    expect(User.on_standby.count).to be 1

    # Why where(nil)?
    # http://stackoverflow.com/questions/18198963/with-rails-4-model-scoped-is-deprecated-but-model-all-cant-replace-it
    expect(User.where(nil).to_a.size).to be 2
    expect(User.on_standby(:two).where(nil).to_a.size).to be 0
    expect(User.on_standby.where(nil).to_a.size).to be 1
  end

  it 'does not interfere with setting inverses' do
    user = User.first
    user.update(name: 'a different name')
    expect(user.items.first.user.name).to eq('a different name')
  end
end
