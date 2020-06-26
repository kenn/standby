# Standby - Read from standby databases for ActiveRecord (formerly Slavery)

[![Build Status](https://travis-ci.org/kenn/standby.svg)](https://travis-ci.org/kenn/standby)

Standby is a simple, easy to use gem for ActiveRecord that enables conservative reading from standby databases, which means it won't automatically redirect all SELECTs to standbys.

Instead, you can do `Standby.on_standby { User.count }` to send a particular query to a standby.

Background: Probably your app started off with one single database. As it grows, you would upgrade to a primary-standby (or primary-replica) replication for redundancy. At this point, all queries still go to the primary and standbys are just backups. With that configuration, it's tempting to run some long-running queries on one of the standbys. And that's exactly what Standby does.

* Conservative - Safe by default. Installing Standby won't change your app's current behavior.
* Future proof - No dirty hacks. Simply works as a proxy for `ActiveRecord::Base.connection`.
* Simple code - Intentionally small. You can read the entire source and completely stay in control.

Standby works with ActiveRecord 3 or later.

## Install

Add this line to your application's Gemfile:

```ruby
gem 'standby'
```

And create standby configs for each environment.

```yaml
development:
  database: myapp_development

development_standby:
  database: myapp_development
```

By convention, config keys with `[env]_standby` are automatically used for standby reads.

Notice that we just copied the settings of `development` to `development_standby`. For `development` and `test`, it's actually recommended as probably you don't want to have replicating multiple databases on your machine. Two connections to the same identical database should be fine for testing purpose.

In case you prefer DRYer definition, YAML's aliasing and key merging might help.

```yaml
common: &common
  adapter: mysql2
  username: root
  database: myapp_development

development:
  <<: *common

development_standby:
  <<: *common
```

Optionally, you can use a database url for your connections:

```yaml
development: postgres://root:@localhost:5432/myapp_development
development_standby: postgres://root:@localhost:5432/myapp_development_standby
```

At this point, Standby does nothing. Run tests and confirm that nothing is broken.

## Usage

To start using Standby, you need to add `Standby.on_standby` in your code. Queries in the `Standby.on_standby` block run on the standby.

```ruby
Standby.on_standby { User.count }   # => runs on standby
Standby.on_standby(:two) { User.count }  # => runs on another standby configured as `development_standby_two`
```

You can nest `on_standby` and `on_primary` interchangeably. The following code works as expected.

```ruby
Standby.on_standby do
  ...
  Standby.on_primary do
    ...
  end
  ...
end
```

Alternatively, you may call `on_standby` directly on the scope, so that the query will be read from standby when it's executed.

```ruby
User.on_standby.where(active: true).count
```

Caveat: `pluck` is not supported by the scope syntax, you still need `Standby.on_standby` in this case.

## Read-only user

For an extra safeguard, it is recommended to use a read-only user for standby access.

```yaml
development_standby:
  <<: *common
  username: readonly
```

With MySQL, `GRANT SELECT` creates a read-only user.

```SQL
GRANT SELECT ON *.* TO 'readonly'@'localhost';
```

With this user, writes on a standby should raise an exception.

```ruby
Standby.on_standby { User.create }  # => ActiveRecord::StatementInvalid: Mysql2::Error: INSERT command denied...
```

With Postgres you can set the entire database to be readonly:

```SQL
ALTER DATABASE myapp_development_standby SET default_transaction_read_only = true;
```

It is a good idea to confirm this behavior in your test code as well.

## Disable temporarily

You can quickly disable standby reads by dropping the following line in `config/initializers/standby.rb`.

```ruby
Standby.disabled = true
```

With this line, Standby stops connection switching and all queries go to the primary.

This may be useful when one of the primary or the standby goes down. You would rewrite `database.yml` to make all queries go to the surviving database, until you restore or rebuild the failed one.

## Transactional fixtures

When `use_transactional_fixtures` is set to `true`, it's NOT recommended to
write to the database besides fixtures, since the standby connection is not aware
of changes performed in the primary connection due to [transaction isolation](https://en.wikipedia.org/wiki/Isolation_(database_systems)).

In that case, you are suggested to disable Standby in the test environment by
putting the following in `test/test_helper.rb`
(or `spec/spec_helper.rb` for RSpec users):

```ruby
Standby.disabled = true
```

## Upgrading from version 3 to version 4

The gem name has been changed from `slavery` to `standby`.

Update your Gemfile

```ruby
gem 'standby'
```

Then

* Replace `Slavery` with `Standby`, `on_slave` with `on_standby`, and `on_master` with `on_primary`
* Update keys in `database.yml` (e.g. `development_slave` to `development_standby`)

## Upgrading from version 2 to version 3

Please note that `Standby.spec_key=` method has been removed from version 3.

## Support for non-Rails apps

If you're using ActiveRecord in a non-Rails app (e.g. Sinatra), be sure to set `RACK_ENV` environment variable in the boot sequence, then:

```ruby
require 'standby'

ActiveRecord::Base.configurations = {
  'development' =>          { adapter: 'mysql2', ... },
  'development_standby' =>  { adapter: 'mysql2', ... }
}
ActiveRecord::Base.establish_connection(:development)
```

## Changelog

* v4.0.0: Rename gem from Slavery to Standby
* v3.0.0: Support for multiple standby targets ([@punchh](https://github.com/punchh))
* v2.1.0: Debug log support / Database URL support / Rails 3.2 & 4.0 compatibility (Thanks to [@citrus](https://github.com/citrus))
* v2.0.0: Rails 5 support
