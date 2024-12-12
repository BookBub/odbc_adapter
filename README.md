# ODBCAdapter

An ActiveRecord ODBC adapter. Master branch is working off of Rails 5.0.1. Previous work has been done to make it compatible with Rails 3.2 and 4.2; for those versions use the 3.2.x or 4.2.x gem releases.

This adapter will work for basic queries for most DBMSs out of the box, without support for migrations. Full support is built-in for MySQL 5 and PostgreSQL 9 databases. You can register your own adapter to get more support for your DBMS using the `ODBCAdapter.register` function.

A lot of this work is based on [OpenLink's ActiveRecord adapter](http://odbc-rails.rubyforge.org/) which works for earlier versions of Rails.

## Installation

Ensure you have the ODBC driver installed on your machine. You will also need the driver for whichever database to which you want ODBC to connect.

Add this line to your application's Gemfile:

```ruby
gem 'odbc_adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install odbc_adapter

## Usage

Configure your `database.yml` by either using the `dsn` option to point to a DSN that corresponds to a valid entry in your `~/.odbc.ini` file:

```
development:
  adapter:  odbc
  dsn: MyDatabaseDSN
```

or by using the `conn_str` option and specifying the entire connection string:

```
development:
  adapter: odbc
  conn_str: "DRIVER={PostgreSQL ANSI};SERVER=localhost;PORT=5432;DATABASE=my_database;UID=postgres;"
```

ActiveRecord models that use this connection will now be connecting to the configured database using the ODBC driver.

## Testing

To run the tests, you'll need the ODBC driver as well as the connection adapter for each database against which you're trying to test. You'll then need to set either the `CONN_STR` or `DSN` env var to point at the database and driver you're using.

1. Install ruby 3.2

   - If you don't already have ruby 3.2 installed locally, one option is using rbenv via the following:

      1. Install [rbenv](https://github.com/rbenv/rbenv?tab=readme-ov-file#homebrew) via homebrew
      2. `rbenv install 3.2.0`
      3. `rbenv local 3.2.0`

   - Note: if you are using nix for local development of other apps, the version of libyaml installed by this method can interfere with the building of native extensions for those apps. To fix that, you'll need to run `brew uninstall --ignore-dependencies libyaml` and re-run your bundle install inside of that nix shell. You'll then need to reinstall libyaml via homebrew if you want to work on this gem.

2. Install `unixodbc` and `ruby-odbc`:

   -  `brew install unixodbc`
   -  `brew list unixodbc`
   -  `gem install ruby-odbc -- --with-odbc-dir=/path/to/unixodbc`

3. Run `bundle install` in this directory to install the relevant gems

4. Install the odbc driver for your database

    - Postgres example:

        1. Install postgres via [installer or homebrew](https://www.postgresql.org/download/macosx/) (if not already installed)

        2. Install the driver via [homebrew](https://formulae.brew.sh/formula/psqlodbc): `brew install psqlodbc`

        3. Create a `~/.odbcinst.ini` pointing to your driver:

            ```
            [PostgreSQL ANSI]
            Description     = Postgres connection
            Driver          = /opt/homebrew/Cellar/psqlodbc/17.00.0003/lib/psqlodbcw.so
            UsageCount      = 1
            Debug           = 0
            CommLog         = 1
            ```

5. Configure your database connection

    - Create a postgres database to use or get the configuration details for an existing one. To create a new db:

        - `psql` (in a terminal)
        - `CREATE DATABASE odbc_adapter_development;`
        - `CREATE USERNAME_HERE foo WITH PASSWORD 'PASSWORD_HERE';`
        - `GRANT ALL PRIVILEGES ON DATABASE foo_development to USERNAME_HERE;`

   - Using `CONN_STR`:

     1. Set a CONN_STR with the connection details: `set CONN_STR="DRIVER={PostgreSQL ANSI};SERVER=127.0.0.2;PORT=5432;DATABASE=odbc_adapter_development;UID=USERNAME_HERE;password=PASSWORD_HERE"`

   - Using `DSN`

     1. Create a `~/.odbc.ini` with the details of your db connection:

         ```
         [postgres_odbc_connection]
         Driver          =       PostgreSQL ANSI
         Description     =       test
         Database        =       odbc_adapter_development
         Server          =       127.0.0.2
         Readonly        =       No
         Port            =       5432
         Trace           =       No
         ```
     2. Set a DSN pointing at the connection details: `set DSN="postgres_odbc_connection"`

5. Running Tests

  - Run `bundle exec rake test` and the test suite will be run by connecting to your database.

  - You can run an individual test file by setting the TEST var, ex. `bundle exec rake test TEST=test/registry_test.rb`


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/localytics/odbc_adapter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
