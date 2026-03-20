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

  test "comments returns at most 20 by default" do
    post = Post.create!(title: "Test", content: "Content", user: @user)
    25.times { |i| post.comments.create!(content: "Comment #{i}", user: @user) }

    result = BackendSchema.execute("{ posts { id comments { id } } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal 20, post_result["comments"].length
  end

  test "comments respects limit argument" do
    post = Post.create!(title: "Test", content: "Content", user: @user)
    5.times { |i| post.comments.create!(content: "Comment #{i}", user: @user) }

    result = BackendSchema.execute("{ posts { id comments(limit: 3) { id } } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal 3, post_result["comments"].length
  end

  test "comments respects offset argument" do
    post = Post.create!(title: "Test", content: "Content", user: @user)
    3.times { |i| post.comments.create!(content: "Comment #{i}", user: @user) }
    all_ids = post.comments.order(created_at: :desc).pluck(:id).map(&:to_s)

    result = BackendSchema.execute("{ posts { id comments(limit: 2, offset: 1) { id } } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal all_ids[1..2], post_result["comments"].map { |c| c["id"] }
  end

  test "comments returns newest first" do
    post = Post.create!(title: "Test", content: "Content", user: @user)
    first  = post.comments.create!(content: "First",  user: @user)
    second = post.comments.create!(content: "Second", user: @user)

    result = BackendSchema.execute("{ posts { id comments { id } } }", context: CONTEXT)
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }
    returned_ids = post_result["comments"].map { |c| c["id"] }

    assert_equal [second.id.to_s, first.id.to_s], returned_ids
  end

  def teardown
    @user.destroy
  end
end
