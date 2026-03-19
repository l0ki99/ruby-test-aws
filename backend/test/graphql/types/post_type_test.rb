require "test_helper"

class Types::PostTypeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", name: "testuser")
  end

  test "image_url returns null when not set" do
    post = Post.create!(title: "Test", content: "Content", user: @user)

    result = BackendSchema.execute("{ posts { id imageUrl } }", context: {})
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_nil post_result["imageUrl"]
  end

  test "image_url returns the correct value when set" do
    post = Post.create!(title: "Test", content: "Content", user: @user, image_url: "/cat.png")

    result = BackendSchema.execute("{ posts { id imageUrl } }", context: {})
    post_result = result["data"]["posts"].find { |p| p["id"] == post.id.to_s }

    assert_equal "/cat.png", post_result["imageUrl"]
  end

  def teardown
    @user.destroy
  end
end
