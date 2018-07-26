require 'rubygems'
require 'bundler/setup'

ENV['RACK_ENV'] = 'test'

require 'standby'

ActiveRecord::Base.configurations = {
  'test'            =>  { 'adapter' => 'sqlite3', 'database' => 'test_db' },
  'test_standby'      =>  { 'adapter' => 'sqlite3', 'database' => 'test_standby_one' },
  'test_standby_two'  =>  { 'adapter' => 'sqlite3', 'database' => 'test_standby_two'},
  'test_standby_url'  =>  'postgres://root:@localhost:5432/test_standby'
}

# Prepare databases
class User < ActiveRecord::Base
  has_many :items
end

class Item < ActiveRecord::Base
  belongs_to :user
end

class Seeder
  def run
    # Populate on primary
    connect(:test)
    create_tables
    User.create
    User.create
    User.first.items.create

    # Populate on standby, emulating replication lag
    connect(:test_standby)
    create_tables
    User.create

    # Populate on standby two
    connect(:test_standby_two)
    create_tables

    # Reconnect to primary
    connect(:test)
  end

  def create_tables
    ActiveRecord::Base.connection.create_table :users, force: true
    ActiveRecord::Base.connection.create_table :items, force: true do |t|
      t.references :user
    end
  end

  def connect(env)
    ActiveRecord::Base.establish_connection(env)
  end
end

Seeder.new.run
