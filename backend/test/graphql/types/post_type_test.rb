require "test_helper"
require "ostruct"

class Types::PostTypeTest < ActiveSupport::TestCase
  CONTEXT = { request: OpenStruct.new(remote_ip: "127.0.0.1") }.freeze

  def setup
    @user = User.create!(email: "test@example.com", name: "testuser")
  end

  test "image_url returns null when not set" do
    post = Post.create!(title: "Test", content: "Content", user: @user)

    result = BackendSchema.execute("{ posts { id imageUrl } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_nil post_result["imageUrl"]
  end

  test "image_url returns the correct value when set" do
    post = Post.create!(title: "Test", content: "Content", user: @user, image_url: "/cat.png")

    result = BackendSchema.execute("{ posts { id imageUrl } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal "/cat.png", post_result["imageUrl"]
  end

  test "comment_counter returns 0 for a post with no comments" do
    post = Post.create!(title: "Test", content: "Content", user: @user)

    result = BackendSchema.execute("{ posts { id commentCounter } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal 0, post_result["commentCounter"]
  end

  test "comment_counter returns the correct count" do
    post = Post.create!(title: "Test", content: "Content", user: @user)
    2.times { post.comments.create!(content: "A comment", user: @user) }

    result = BackendSchema.execute("{ posts { id commentCounter } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal 2, post_result["commentCounter"]
  end

  def teardown
    @user.destroy
  end
end
