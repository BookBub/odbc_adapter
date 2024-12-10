module ODBCAdapter
  module Adapters
    # A default adapter used for databases that are no explicitly listed in the
    # registry. This allows for minimal support for DBMSs for which we don't
    # have an explicit adapter.
    class NullODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      IDENTIFIER_QUOTE_CHAR = "\"".freeze

      # Using the generic ToSql visitor (to attempt to get as much coverage as possible for
      # DBMSs we don't support).
      def arel_visitor
        Arel::Visitors::ToSql.new(self)
      end

      def self.quote_column_name(name)
        name = name.to_s
        quote_char = IDENTIFIER_QUOTE_CHAR.to_s.strip

        return name if quote_char.length.zero?
        quote_char = quote_char[0]

        # Avoid quoting any already quoted name
        return name if name[0] == quote_char && name[-1] == quote_char

        # Only quote mixed case names since identifiers are upcase.
        # This may cause issues with DBs that don't use upcase identifiers
        return name unless name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/

        "#{quote_char.chr}#{name}#{quote_char.chr}"
      end

      # Explicitly turning off prepared_statements in the null adapter because
      # there isn't really a standard on which substitution character to use.
      def prepared_statements
        false
      end

      # Turning off support for migrations because there is no information to
      # go off of for what syntax the DBMS will expect.
      def supports_migrations?
        false
      end
    end
  end
end
