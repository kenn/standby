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
end

# Create two records on master
ActiveRecord::Base.establish_connection(:test)
ActiveRecord::Base.connection.create_table :users, force: true
User.create
User.create

# Create one record on slave, emulating replication lag
ActiveRecord::Base.establish_connection(:test_slave)
ActiveRecord::Base.connection.create_table :users, force: true
User.create

# Reconnect to master
ActiveRecord::Base.establish_connection(:test)
