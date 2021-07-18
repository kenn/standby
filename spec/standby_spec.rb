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

  context 'transaction safeguard' do
    context 'when not in a transaction' do
      subject do
        Standby.on_standby do
          ActiveRecord::Base.connection.execute('SELECT 1;')
        end
      end

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when in a transaction' do
      subject do
        ActiveRecord::Base.transaction do
          Standby.on_standby do
            ActiveRecord::Base.connection.execute('SELECT 1;')
          end
        end
      end

      it 'raises' do
        expect { subject }.to raise_error(Standby::Error, 'on_standby cannot be used inside transaction block!')
      end
    end

    context 'with exhausted connection pool' do
      let!(:busy_connection_count_before_test) { connection_pool.stat[:busy] }
      let!(:checkout_timeout_before_test)      { connection_pool.checkout_timeout }

      let(:connection_pool) { ActiveRecord::Base.connection_handler.retrieve_connection_pool('primary') }

      let(:exhaust_connection_pool_thread) do
        # Use a separate thread so that all connections will be returned to the pool when the thread is killed.
        Thread.start do
          connection_pool.checkout(0) while connection_pool.stat[:busy] < connection_pool.stat[:size]

          # Keep alive, otherwise the connections will be returned to the pool.
          sleep
        end
      end

      before do
        # Speed up the test by not waiting.
        connection_pool.checkout_timeout = 0

        # Start a thread which will check out all connections from the primary connection pool.
        exhaust_connection_pool_thread

        # Wait for the pool to be exhausted. Busy wait is so simple!
        remaining = 5.0
        until connection_pool.stat[:busy] == connection_pool.stat[:size]
          raise 'failed to exhaust connection pool' if remaining <= 0
          remaining -= 0.2
          sleep 0.2
        end
      end

      after do
        connection_pool.checkout_timeout = checkout_timeout_before_test

        # Kill the thread holding on to all the connections. Wait for it to die so that reap will see it is no longer active.
        exhaust_connection_pool_thread.kill.join

        # Reap will return any connections owned by dead threads to the pool.
        connection_pool.reap

        # Ensure we are back to where we were before the test.
        if connection_pool.stat[:busy] != busy_connection_count_before_test
          raise 'failed to reap unused connections'
        end
      end

      context 'with no available connection on current thread' do
        context 'with active connection check' do
          subject do
            thread = Thread.start do
              Standby.on_standby do
                ActiveRecord::Base.connection.execute('SELECT 1;')
              end
            end
            thread.report_on_exception = false
            thread.join
          end

          it 'does not block' do
            expect { subject }.not_to raise_error
          end
        end

        # Demonstrates the issue covered by the previous test and ensures the test setup functions correctly.
        context 'without active connection check' do
          subject do
            thread = Thread.start do
              ActiveRecord::Base.connection.open_transactions
            end
            thread.report_on_exception = false
            thread.join
          end

          it 'blocks' do
            expect { subject }.to raise_error(ActiveRecord::ConnectionTimeoutError)
          end
        end
      end

      context 'with available connection on current thread' do
        before do
          # Causes the connection pool to share connections with all threads.
          connection_pool.lock_thread = Thread.current
        end

        after do
          connection_pool.lock_thread = nil
        end

        context 'when in a transaction' do
          subject do
            ActiveRecord::Base.transaction do
              Standby.on_standby do
                ActiveRecord::Base.connection.execute('SELECT 1;')
              end
            end
          end

          it 'reuses existing connection and raises' do
            expect { subject }.to raise_error(Standby::Error, 'on_standby cannot be used inside transaction block!')
          end
        end

        context 'when not in a transaction' do
          subject do
            Standby.on_standby do
              ActiveRecord::Base.connection.execute('SELECT 1;')
            end
          end

          it 'reuses existing connection and does not raise' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end
end
