require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", name: "testuser")
    @post = Post.create!(title: "Test Post", content: "Content", user: @user)
  end

  test "creating a comment increments post comment_counter" do
    assert_difference -> { @post.reload.comment_counter }, +1 do
      @post.comments.create!(content: "A comment", user: @user)
    end
  end

  test "destroying a comment decrements post comment_counter" do
    comment = @post.comments.create!(content: "A comment", user: @user)

    assert_difference -> { @post.reload.comment_counter }, -1 do
      comment.destroy
    end
  end

  test "creating a comment sets last_comment_at on the post" do
    comment = @post.comments.create!(content: "A comment", user: @user)

    assert_equal comment.created_at, @post.reload.last_comment_at
  end

  test "creating a newer comment updates last_comment_at to the newer timestamp" do
    @post.comments.create!(content: "First comment", user: @user)
    newer = @post.comments.create!(content: "Second comment", user: @user)

    assert_equal newer.created_at, @post.reload.last_comment_at
  end

  test "destroying the only comment sets last_comment_at to nil" do
    comment = @post.comments.create!(content: "Only comment", user: @user)
    comment.destroy

    assert_nil @post.reload.last_comment_at
  end

  test "destroying the latest comment rolls last_comment_at back to the previous comment" do
    older = @post.comments.create!(content: "Older", user: @user, created_at: 2.hours.ago)
    newer = @post.comments.create!(content: "Newer", user: @user)
    newer.destroy

    assert_equal older.created_at, @post.reload.last_comment_at
  end

  test "creating a comment busts the trending posts cache" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("trending_posts_cache_version", 42)

    @post.comments.create!(content: "A comment", user: @user)

    assert_nil Rails.cache.read("trending_posts_cache_version"),
               "Expected trending_posts_cache_version to be deleted after comment creation"
  ensure
    Rails.cache = original_cache
  end

  test "destroying a comment busts the trending posts cache" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    comment = @post.comments.create!(content: "A comment", user: @user)
    Rails.cache.write("trending_posts_cache_version", 42)

    comment.destroy

    assert_nil Rails.cache.read("trending_posts_cache_version"),
               "Expected trending_posts_cache_version to be deleted after comment destruction"
  ensure
    Rails.cache = original_cache
  end

  def teardown
    @user.destroy
  end
end
