require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      name: "testuser"
    )
    @post = Post.new(
      title: "Test Post",
      content: "This is a test post content",
      user: @user
    )
  end

  test "should be valid" do
    assert @post.valid?
  end

  test "title should be present" do
    @post.title = ""
    assert_not @post.valid?
  end

  test "content should be present" do
    @post.content = ""
    assert_not @post.valid?
  end

  test "user should be present" do
    @post.user = nil
    assert_not @post.valid?
  end

  test "should belong to a user" do
    assert_respond_to @post, :user
    assert_instance_of User, @post.user
  end

  test "should have many comments" do
    assert_respond_to @post, :comments
  end

  test "should order comments by created_at" do
    @post.save!
    comment1 = @post.comments.create!(
      content: "First comment",
      user: @user,
      created_at: 1.hour.ago
    )
    comment2 = @post.comments.create!(
      content: "Second comment",
      user: @user,
      created_at: Time.current
    )
    
    assert_equal [comment2, comment1], @post.comments.order(created_at: :desc)
  end

  test "saving a post busts the posts cache version" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("posts_cache_version", 12345)

    @post.save!

    assert_nil Rails.cache.read("posts_cache_version"),
      "Expected posts_cache_version to be deleted after saving a post"
  ensure
    Rails.cache = original_cache
  end

  def teardown
    @user.destroy
  end
end
