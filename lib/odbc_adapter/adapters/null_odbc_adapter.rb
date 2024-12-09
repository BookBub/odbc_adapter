module ODBCAdapter
  module Adapters
    # A default adapter used for databases that are no explicitly listed in the
    # registry. This allows for minimal support for DBMSs for which we don't
    # have an explicit adapter.
    class NullODBCAdapter < ActiveRecord::ConnectionAdapters::ODBCAdapter
      # Using the generic ToSql visitor so that the SQL string gets substituted before it is
      # sent to the DBMS (to attempt to get as much coverage as possible for
      # DBMSs we don't support).
      def arel_visitor
        Arel::Visitors::ToSql.new(self)
      end

      def self.quote_column_name(name)
        name = name.to_s
        quote_char = identifier_quote_char.to_s.strip

        return name if quote_char.length.zero?
        quote_char = quote_char[0]

        # Avoid quoting any already quoted name
        return name if name[0] == quote_char && name[-1] == quote_char

        # If upcase identifiers, only quote mixed case names.
        if upcase_identifiers?
          return name unless name =~ /([A-Z]+[a-z])|([a-z]+[A-Z])/
        end

        "#{quote_char.chr}#{name}#{quote_char.chr}"
      end

      def self.identifier_quote_char
        "\""
      end

      def self.upcase_identifiers?
        true
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
