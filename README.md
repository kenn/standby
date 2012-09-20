# Slavery - Simple, conservative slave read for ActiveRecord

Slavery is a simple, easy to use plugin for ActiveRecord that enables conservative slave reads, which means it doesn't automatically redirect all SELECTs to slaves. Instead, it lets you specify `Slavery.on_slave { User.count }` to send a particular query to a slave.

Probably you just start off with one single database. As your app grows, you would move to master-slave replication for redundancy. At this point, all queries still go to the master and slaves are just backups. With that configuration, it's tempting to run some long-running queries on the slave. And that's exactly what Slavery does.

* Conservative - Safe by default. Installing Slavery won't change your app's current behavior.
* Future proof - No dirty hacks, simply works as a proxy for `ActiveRecord::Base.connection`.
* Simple - Less than 100 LOC, you can read the entire source and completely stay in control.

Slavery works with ActiveRecord 3 or later.

## Install

Add this line to your application's Gemfile:

```ruby
gem 'slavery'
```

And create slave configs for each environment.

```yaml
development:
  adapter: mysql2
  username: root
  database: myapp_development

development_slave:
  adapter: mysql2
  username: root
  database: myapp_development
```

By convention, config keys with `[env]_slave` are automatically used for slave reads.

Notice that you just copied the settings for `development` to `development_slave`. For `development` and `test`, it's actually recommended as probably you don't want to have replicating multiple databases on your machine. Two connections to the same identical database should be fine for testing purpose.

At this point, Slavery does nothing. Run tests and confirm that anything isn't broken.

## Usage

To start using Slavery, you need to add `Slavery.on_slave` in your code. Queries in the `Slavery.on_slave` block run on the slave.

```ruby
Slavery.on_slave { User.count } 	# => runs on slave
```

You can nest `on_slave` and `on_master` interchangeably. The following code works as expected.

```ruby
Slavery.on_slave do
  ...
  Slavery.on_master do
    ...
  end
  ...
end
```

## Read-only user

For an extra safeguard, it is recommended to use a read-only user for slave access.

```ruby
development_slave:
  adapter: mysql2
  username: readonly
  database: myapp_development
```

With MySQL, `GRANT SELECT` creates the user.

```SQL
GRANT SELECT ON *.* TO 'readonly'@'localhost';
```

With this setting, writes on slave should raises an exception.

```ruby
Slavery.on_slave { User.create } 	# => ActiveRecord::StatementInvalid: Mysql2::Error: INSERT command denied...
```

## Database failure

When one of the master or the slave goes down, you would rewrite `database.yml` to make all queries go to the surviving database, until you recover or rebuild the failed one.

In such an event, you don't want to manually remove `Slavery.on_slave` from your code. Instead, just put the following line in `config/initializers/slavery.rb`.

```ruby
Slavely.disabled = true
```

With this line, Slavery stops connection switching and all queries go to the new master database.

## Support for non-Rails apps

If you're using ActiveRecord in a non-Rails app (e.g. Sinatra), be sure to set `Slavery.env` in the boot sequence.

```ruby
Slavery.env = 'development'

ActiveRecord::Base.send(:include, Slavery)

ActiveRecord::Base.configurations = {
  'development' =>        { adapter: 'mysql2', ... },
  'development_slave' =>  { adapter: 'mysql2', ... }
}
ActiveRecord::Base.establish_connection(:development)
```
