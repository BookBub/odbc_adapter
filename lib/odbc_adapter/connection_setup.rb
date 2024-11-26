module ODBCAdapter
  class ConnectionSetup
    attr_reader :config
    attr_reader :connection

    def initialize(config)
      @config = config
      @connection = nil
    end

    def build
      if @config.key?(:dsn)
        odbc_dsn_connection
      elsif @config.key?(:conn_str)
        odbc_conn_str_connection
      else
        raise ArgumentError, 'No data source name (:dsn) or connection string (:conn_str) specified.'
      end
    end

    private

    # Connect using a predefined DSN.
    def odbc_dsn_connection
      username   = @config[:username] ? @config[:username].to_s : nil
      password   = @config[:password] ? @config[:password].to_s : nil
      @connection = ODBC.connect(config[:dsn], username, password)
      @config.merge!(username: username, password: password)
    end

    # Connect using ODBC connection string
    # Supports DSN-based or DSN-less connections
    # e.g. "DSN=virt5;UID=rails;PWD=rails"
    #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
    def odbc_conn_str_connection
      driver = ODBC::Driver.new
      driver.name = 'odbc'
      driver.attrs = @config[:conn_str].split(';').map { |option| option.split('=', 2) }.to_h

      @connection = ODBC::Database.new.drvconnect(driver)
      @config.merge!(driver: driver)
    end
  end
end
