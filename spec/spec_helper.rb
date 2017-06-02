require 'rubygems'
require 'bundler/setup'

ENV['RACK_ENV'] = 'test'

require 'slavery'

ActiveRecord::Base.configurations = {
  'test'            =>  { 'adapter' => 'sqlite3', 'database' => 'test_db' },
  'test_slave'      =>  { 'adapter' => 'sqlite3', 'database' => 'test_slave_db' },
  'test_slave_url'  =>  'postgres://root:@localhost:5432/test_slave'
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
    # Populate on master
    connect(:test)
    create_tables
    User.create
    User.create
    User.first.items.create

    # Populate on slave, emulating replication lag
    connect(:test_slave)
    create_tables
    User.create

    # Reconnect to master
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
