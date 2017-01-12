module ODBCAdapter
  module Quoting
    # Quotes a string, escaping any ' (single quote) characters.
    def quote_string(string)
      string.gsub(/\'/, "''")
    end

    # Returns a quoted form of the column name.
    def quote_column_name(name)
      name = name.to_s
      quote_char = dbms.field_for(ODBC::SQL_IDENTIFIER_QUOTE_CHAR).to_s.strip

      return name if quote_char.length.zero?
      quote_char = quote_char[0]

      # Avoid quoting any already quoted name
      return name if name[0] == quote_char && name[-1] == quote_char

      # If DBMS's SQL_IDENTIFIER_CASE = SQL_IC_UPPER, only quote mixed
      # case names.
      if dbms.field_for(ODBC::SQL_IDENTIFIER_CASE) == ODBC::SQL_IC_UPPER
        return name unless (name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/)
      end

      "#{quote_char.chr}#{name}#{quote_char.chr}"
    end

    def quoted_true
      '1'
    end

    # Ideally, we'd return an ODBC date or timestamp literal escape
    # sequence, but not all ODBC drivers support them.
    def quoted_date(value)
      if value.acts_like?(:time) # Time, DateTime
        "'#{value.strftime("%Y-%m-%d %H:%M:%S")}'"
      else # Date
        "'#{value.strftime("%Y-%m-%d")}'"
      end
    end
  end
end
