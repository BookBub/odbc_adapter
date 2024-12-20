require 'active_record'
require 'arel/visitors/visitor'
require 'odbc'

require 'odbc_adapter/database_limits'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/error'
require 'odbc_adapter/quoting'
require 'odbc_adapter/schema_statements'

require 'odbc_adapter/column'
require 'odbc_adapter/column_metadata'
require 'odbc_adapter/connection_setup'
require 'odbc_adapter/database_metadata'
require 'odbc_adapter/registry'
require 'odbc_adapter/version'

module ActiveRecord
  # Deprecated: Provides backwards-compatible support for Rails 7.1
  class Base
    class << self
      # Build a new ODBC connection with the given configuration.
      def odbc_connection(config)
        config = config.symbolize_keys
        setup = ::ODBCAdapter::ConnectionSetup.new(config.symbolize_keys)
        setup.build

        database_metadata = ::ODBCAdapter::DatabaseMetadata.new(setup.connection)
        database_metadata.adapter_class.new(setup.connection, logger, nil, setup.config, database_metadata)
      end
    end
  end

  module ConnectionAdapters
    class ODBCAdapter < AbstractAdapter
      include ::ODBCAdapter::DatabaseLimits
      include ::ODBCAdapter::DatabaseStatements
      include ::ODBCAdapter::Quoting
      include ::ODBCAdapter::SchemaStatements

      ADAPTER_NAME = 'ODBC'.freeze
      BOOLEAN_TYPE = 'BOOLEAN'.freeze

      ERR_DUPLICATE_KEY_VALUE     = 23_505
      ERR_QUERY_TIMED_OUT         = 57_014
      ERR_QUERY_TIMED_OUT_MESSAGE = /Query has timed out/

      # The object that stores the information that is fetched from the DBMS
      # when a connection is first established.
      attr_reader :database_metadata

      def initialize(config_or_deprecated_connection, deprecated_logger = nil, deprecated_connection_options = nil, deprecated_config = nil, database_metadata = nil)
        super(config_or_deprecated_connection, deprecated_logger, deprecated_connection_options, deprecated_config)
        if config_or_deprecated_connection.try(:get_info, ODBC.const_get("SQL_DBMS_NAME"))
          @raw_connection = config_or_deprecated_connection
          @config = deprecated_config
          configure_time_options(@raw_connection)
        else
          config = config_or_deprecated_connection
          setup = ::ODBCAdapter::ConnectionSetup.new(config.symbolize_keys)
          setup.build
          @config = setup.config
          connect
        end

        @database_metadata = ::ODBCAdapter::DatabaseMetadata.new(@raw_connection)
      end

      # Returns the human-readable name of the adapter.
      def adapter_name
        ADAPTER_NAME
      end

      # Does this adapter support migrations? Backend specific, as the abstract
      # adapter always returns +false+.
      def supports_migrations?
        true
      end

      # ODBC adapter does not support the returning clause
      def supports_insert_returning?
        false
      end

      # CONNECTION MANAGEMENT ====================================

      # Checks whether the connection to the database is still active. This
      # includes checking whether the database is actually capable of
      # responding, i.e. whether the connection isn't stale.
      def active?
        @raw_connection.connected?
      end

      # Establishes a new connection with the database.
      def connect
        @raw_connection =
          if @config.key?(:dsn)
            ODBC.connect(@config[:dsn], @config[:username], @config[:password])
          else
            ODBC::Database.new.drvconnect(@config[:driver])
          end
        configure_time_options(@raw_connection)
      end

      # Disconnects from the database if already connected, and establishes a
      # new connection with the database.
      def reconnect
        disconnect!
        connect
      end
      alias reset! reconnect!

      # Disconnects from the database if already connected. Otherwise, this
      # method does nothing.
      def disconnect!
        @raw_connection.disconnect if @raw_connection.connected?
      end

      # Build a new column object from the given options. Effectively the same
      # as super except that it also passes in the native type.
      # rubocop:disable Metrics/ParameterLists
      def new_column(name, default, sql_type_metadata, null, native_type = nil)
        ::ODBCAdapter::Column.new(name, default, sql_type_metadata, null, native_type)
      end

      # odbc_adapter does not support returning, so there are no return values from an insert
      def return_value_after_insert?(column) # :nodoc:
        false
      end

      protected

      # Build the type map for ActiveRecord
      def initialize_type_map(map)
        map.register_type 'boolean',              Type::Boolean.new
        map.register_type ODBC::SQL_CHAR,         Type::String.new
        map.register_type ODBC::SQL_LONGVARCHAR,  Type::Text.new
        map.register_type ODBC::SQL_TINYINT,      Type::Integer.new(limit: 4)
        map.register_type ODBC::SQL_SMALLINT,     Type::Integer.new(limit: 8)
        map.register_type ODBC::SQL_INTEGER,      Type::Integer.new(limit: 16)
        map.register_type ODBC::SQL_BIGINT,       Type::BigInteger.new(limit: 32)
        map.register_type ODBC::SQL_REAL,         Type::Float.new(limit: 24)
        map.register_type ODBC::SQL_FLOAT,        Type::Float.new
        map.register_type ODBC::SQL_DOUBLE,       Type::Float.new(limit: 53)
        map.register_type ODBC::SQL_DECIMAL,      Type::Float.new
        map.register_type ODBC::SQL_NUMERIC,      Type::Integer.new
        map.register_type ODBC::SQL_BINARY,       Type::Binary.new
        map.register_type ODBC::SQL_DATE,         Type::Date.new
        map.register_type ODBC::SQL_DATETIME,     Type::DateTime.new
        map.register_type ODBC::SQL_TIME,         Type::Time.new
        map.register_type ODBC::SQL_TIMESTAMP,    Type::DateTime.new
        map.register_type ODBC::SQL_GUID,         Type::String.new

        alias_type map, ODBC::SQL_BIT,            'boolean'
        alias_type map, ODBC::SQL_VARCHAR,        ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WCHAR,          ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WVARCHAR,       ODBC::SQL_CHAR
        alias_type map, ODBC::SQL_WLONGVARCHAR,   ODBC::SQL_LONGVARCHAR
        alias_type map, ODBC::SQL_VARBINARY,      ODBC::SQL_BINARY
        alias_type map, ODBC::SQL_LONGVARBINARY,  ODBC::SQL_BINARY
        alias_type map, ODBC::SQL_TYPE_DATE,      ODBC::SQL_DATE
        alias_type map, ODBC::SQL_TYPE_TIME,      ODBC::SQL_TIME
        alias_type map, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP
      end

      private

      # Can't use the built-in ActiveRecord map#alias_type because it doesn't
      # work with non-string keys, and in our case the keys are (almost) all
      # numeric
      def alias_type(map, new_type, old_type)
        map.register_type(new_type) do |_, *args|
          map.lookup(old_type, *args)
        end
      end

      # Ensure ODBC is mapping time-based fields to native ruby objects
      def configure_time_options(connection)
        connection.use_time = true
      end
    end
  end
end
