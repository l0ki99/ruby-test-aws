# frozen_string_literal: true

require "test_helper"
require "ostruct"

class Resolvers::UserResolverTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "user_resolver_test@example.com", name: "testuser")
  end

  def teardown
    @user.destroy
  end

  test "returns the user when a valid id is given" do
    result = BackendSchema.execute("{ user(id: \"#{@user.id}\") { id name } }", context: { request: mock_request })

    assert_nil result["errors"]
    assert_equal @user.id.to_s, result["data"]["user"]["id"]
    assert_equal @user.name, result["data"]["user"]["name"]
  end

  test "returns an error for an unknown id" do
    result = BackendSchema.execute('{ user(id: "0") { id } }', context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_equal "User not found", result["errors"].first["message"]
  end

  test "returns a schema error when id is omitted" do
    result = BackendSchema.execute('{ user { id } }', context: { request: mock_request })

    assert_not_nil result["errors"]
  end

  private

  def mock_request
    OpenStruct.new(remote_ip: "127.0.0.1")
  end
end
