require 'test_helper'

class ConnectionSetupTest < Minitest::Test
  def test_build_dsn_connection
    config = {
      dsn: "dsn",
      username: "foo",
      password: "bar",
    }

    ODBC.stub :connect, "here's your connection" do
      setup = ODBCAdapter::ConnectionSetup.new(config)
      setup.build

      assert_equal "foo", setup.config[:username]
      assert_equal "bar", setup.config[:password]

      assert_equal "here's your connection", setup.connection
    end
  end

  def test_build_conn_str_connection
    mock_database = MockDatabase.new
    ODBC::Database.stub :new, mock_database do
      config = {
        conn_str: "DRIVER={PostgreSQL ANSI};SERVER=127.0.0.1;PORT=5432;DATABASE=db;UID=user;password=password"
      }
      setup = ODBCAdapter::ConnectionSetup.new(config)
      setup.build

      assert_equal "odbc", setup.config[:driver].name
      assert_equal setup.config[:driver], mock_database.driver

      expected_driver_attrs = {
        "DRIVER"=>"{PostgreSQL ANSI}",
        "SERVER"=>"127.0.0.1",
        "PORT"=>"5432",
        "DATABASE"=>"db",
        "UID"=>"user",
        "password"=>"password",
      }
      assert_equal expected_driver_attrs, setup.config[:driver].attrs

      assert_equal "here's your connection", setup.connection
    end
  end

  def test_build_raises_for_unknown_config
    setup = ODBCAdapter::ConnectionSetup.new({})

    expected_error_message = "No data source name (:dsn) or connection string (:conn_str) specified."
    assert_raises(ArgumentError, expected_error_message) { setup.build }
  end

  class MockDatabase
    attr_reader :driver

    def initialize
      @driver = nil
    end

    def drvconnect(driver)
      @driver = driver
      "here's your connection"
    end
  end
end
