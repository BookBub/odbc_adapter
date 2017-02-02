module ODBCAdapter
  # Caches SQLGetInfo output
  class DBMS
    FIELDS = [
      ODBC::SQL_DBMS_NAME,
      ODBC::SQL_DBMS_VER,
      ODBC::SQL_IDENTIFIER_CASE,
      ODBC::SQL_QUOTED_IDENTIFIER_CASE,
      ODBC::SQL_IDENTIFIER_QUOTE_CHAR,
      ODBC::SQL_MAX_IDENTIFIER_LEN,
      ODBC::SQL_MAX_TABLE_NAME_LEN,
      ODBC::SQL_USER_NAME,
      ODBC::SQL_DATABASE_NAME
    ]

    attr_reader :fields

    def initialize(connection)
      @fields = Hash[FIELDS.map { |field| [field, connection.get_info(field)] }]
    end

    def adapter_class
      ODBCAdapter.adapter_for(field_for(ODBC::SQL_DBMS_NAME))
    end

    def field_for(field)
      fields[field]
    end
  end
end
