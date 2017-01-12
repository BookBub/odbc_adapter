module ActiveRecord
  class Base
    class << self
      def odbc_connection(config) # :nodoc:
        config = config.symbolize_keys

        connection, options =
          if config.key?(:dsn)
            odbc_dsn_connection(config)
          elsif config.key?(:conn_str)
            odbc_conn_str_connection(config)
          else
            raise ArgumentError, "No data source name (:dsn) or connection string (:conn_str) specified."
          end

        ConnectionAdapters::ODBCAdapter.new(connection, logger, options.merge(
          convert_numeric_literals: config[:convert_numeric_literals] || false,
          emulate_booleans: config[:emulate_booleans] || false
        ))
      end

      private

      def odbc_dsn_connection(config)
        username   = config[:username] ? config[:username].to_s : nil
        password   = config[:password] ? config[:password].to_s : nil
        connection = ODBC.connect(config[:dsn], username, password)
        options    = { dsn: config[:dsn], username: username, password: password }
        [connection, options]
      end

      # Connect using ODBC connection string
      # Supports DSN-based or DSN-less connections
      # e.g. "DSN=virt5;UID=rails;PWD=rails"
      #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
      def odbc_conn_str_connection(config)
        connstr_keyval_pairs = config[:conn_str].split(';')

        driver = ODBC::Driver.new
        driver.name = 'odbc'
        driver.attrs = {}

        connstr_keyval_pairs.each do |pair|
          keyval = pair.split('=')
          driver.attrs[keyval[0]] = keyval[1] if keyval.length == 2
        end

        connection = ODBC::Database.new.drvconnect(driver)
        options    = { conn_str: config[:conn_str], driver: driver }
        [connection, options]
      end
    end
  end

  module ConnectionAdapters
    class ODBCAdapter < AbstractAdapter
      include ::ODBCAdapter::DatabaseStatements
      include ::ODBCAdapter::Quoting
      include ::ODBCAdapter::SchemaStatements

      ADAPTER_NAME = 'ODBC'.freeze

      attr_reader :dbms, :options

      def initialize(connection, logger, options)
        super(connection, logger)

        @connection = connection
        @options    = options

        @dbms    = ::ODBCAdapter::DBMS.new(connection)
        @visitor = dbms.visitor(self)
        self.extend(dbms.ext_module)
      end

      # Returns the human-readable name of the adapter. Use mixed case - one
      # can always use downcase if needed.
      def adapter_name
        ADAPTER_NAME
      end

      # Does this adapter support migrations? Backend specific, as the
      # abstract adapter always returns +false+.
      def supports_migrations?
        true
      end

      # CONNECTION MANAGEMENT ====================================

      # Checks whether the connection to the database is still active. This includes
      # checking whether the database is actually capable of responding, i.e. whether
      # the connection isn't stale.
      def active?
        @connection.connected?
      end

      # Disconnects from the database if already connected, and establishes a
      # new connection with the database.
      def reconnect!
        disconnect!
        @connection =
          if options.key?(:dsn)
            ODBC.connect(options[:dsn], options[:username], options[:password])
          else
            ODBC::Database.new.drvconnect(options[:driver])
          end
      end

      # Disconnects from the database if already connected. Otherwise, this
      # method does nothing.
      def disconnect!
        @connection.disconnect if @connection.connected?
      end
    end
  end
end
