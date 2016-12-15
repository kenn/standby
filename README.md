# Slavery - Simple, conservative slave reads for ActiveRecord

[![Build Status](https://travis-ci.org/citrus/slavery.svg?branch=rails3.2)](https://travis-ci.org/citrus/slavery)

Slavery is a simple, easy to use gem for ActiveRecord that enables conservative slave reads, which means it doesn't automatically redirect all SELECTs to slaves.

Instead, you can do `Slavery.on_slave { User.count }` to send a particular query to a slave.

Background: Probably your app started off with one single database. As it grows, you would upgrade to a master-slave replication for redundancy. At this point, all queries still go to the master and slaves are just backups. With that configuration, it's tempting to run some long-running queries on the slave. And that's exactly what Slavery does.

* Conservative - Safe by default. Installing Slavery won't change your app's current behavior.
* Future proof - No dirty hacks. Simply works as a proxy for `ActiveRecord::Base.connection`.
* Simple code - Intentionally small. You can read the entire source and completely stay in control.

Slavery works with ActiveRecord 3 or later.

## Install

Add this line to your application's Gemfile:

```ruby
gem 'slavery'
```

And create slave configs for each environment.

```yaml
development:
  database: myapp_development

development_slave:
  database: myapp_development
```

By convention, config keys with `[env]_slave` are automatically used for slave reads.

Notice that we just copied the settings of `development` to `development_slave`. For `development` and `test`, it's actually recommended as probably you don't want to have replicating multiple databases on your machine. Two connections to the same identical database should be fine for testing purpose.

In case you prefer DRYer definition, YAML's aliasing and key merging might help.

```yaml
common: &common
  adapter: mysql2
  username: root
  database: myapp_development

development:
  <<: *common

development_slave:
  <<: *common
```

At this point, Slavery does nothing. Run tests and confirm that nothing is broken.

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

Alternatively, you may call `on_slave` directly on the scope, so that the query will be read from slave when it's executed.

```ruby
User.on_slave.where(active: true).count
```

Caveat: `pluck` is not supported by the scope syntax, you still need `Slavery.on_slave` in this case.

## Read-only user

For an extra safeguard, it is recommended to use a read-only user for slave access.

```yaml
development_slave:
  <<: *common
  username: readonly
```

With MySQL, `GRANT SELECT` creates a read-only user.

```SQL
GRANT SELECT ON *.* TO 'readonly'@'localhost';
```

With this user, writes on slave should raise an exception.

```ruby
Slavery.on_slave { User.create } 	# => ActiveRecord::StatementInvalid: Mysql2::Error: INSERT command denied...
```

It is a good idea to confirm this behavior in your test code as well.

## Disable temporarily

You can quickly disable slave reads by dropping the following line in `config/initializers/slavery.rb`.

```ruby
Slavely.disabled = true
```

With this line, Slavery stops connection switching and all queries go to the master.

This may be useful when one of the master or the slave goes down. You would rewrite `database.yml` to make all queries go to the surviving database, until you restore or rebuild the failed one.

## Support for non-Rails apps

If you're using ActiveRecord in a non-Rails app (e.g. Sinatra), be sure to set `RACK_ENV` environment variable in the boot sequence, then:

```ruby
require 'slavery'

ActiveRecord::Base.configurations = {
  'development' =>        { adapter: 'mysql2', ... },
  'development_slave' =>  { adapter: 'mysql2', ... }
}
ActiveRecord::Base.establish_connection(:development)
```

## Custom slave key in database.yml

This is useful for deploying on EngineYard where the configuration key in database.yml is simple "slave". Put the following line in `config/initializers/slavery.rb`.

```ruby
Slavery.spec_key = "slave" #instead of production_slave
```

## Changelog

* v2.0.0: Rails 5 support
