# Requiring with this pattern to mirror ActiveRecord
require 'active_record/connection_adapters/odbc_adapter'
require 'odbc_adapter/adapters/postgresql_odbc_adapter'
require 'odbc_adapter/adapters/mysql_odbc_adapter'
require 'odbc_adapter/adapters/null_odbc_adapter'

def register_adapters
  if ActiveRecord::ConnectionAdapters.respond_to?(:register)
    ActiveRecord::ConnectionAdapters.register(
      "odbc",
      "ODBCAdapter::Adapters::NullODBCAdapter",
      "odbc_adapter/adapters/null_odbc_adapter"
    )
    ActiveRecord::ConnectionAdapters.register(
      "postgres_odbc",
      "ODBCAdapter::Adapters::PostgreSQLODBCAdapter",
      "odbc_adapter/adapters/postgresql_odbc_adapter"
    )
    ActiveRecord::ConnectionAdapters.register(
      "mysql_odbc",
      "ODBCAdapter::Adapters::MySQLODBCAdapter",
      "odbc_adapter/adapters/mysql_odbc_adapter"
    )
  end
end

if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_record) do
    register_adapters
  end
else
  register_adapters
end
