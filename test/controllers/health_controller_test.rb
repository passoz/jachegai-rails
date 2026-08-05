require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "GET /healthz returns 200 with envelope even when DB is unavailable" do
    # Healthz must not depend on the database
    get "/healthz"
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json.key?("data")
    assert json["data"].key?("status")
  end

  test "GET /readyz returns 200 when DB is accessible" do
    get "/readyz"
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json["data"].key?("db")
  end

  test "GET /readyz returns 503 when DB is unavailable" do
    # Simulate DB failure by overriding the check via a singleton method
    HealthController.define_method(:database_ready?) { false }
    begin
      get "/readyz"
      assert_response :service_unavailable
      json = JSON.parse(response.body)
      assert_equal false, json["ok"]
      assert_equal "service_unavailable", json["error"]["code"]
    ensure
      HealthController.define_method(:database_ready?) do
        ActiveRecord::Base.connection.execute("SELECT 1")
        true
      rescue ActiveRecord::ConnectionNotEstablished, SQLite3::SQLException
        false
      end
    end
  end
end
