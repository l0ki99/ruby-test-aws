require "test_helper"
require "ostruct"

class Resolvers::TrendingPostResolverTest < ActiveSupport::TestCase
  QUERY = <<~GQL
    { trendingPosts { id lastCommentAt } }
  GQL

  def setup
    @user = User.create!(email: "trending_test@example.com", name: "trendinguser")
    @post = Post.create!(title: "Test post", content: "Some content", user: @user)
    Rails.cache.clear
  end

  def teardown
    @user.destroy
    Rails.cache.clear
  end

  # — ordering —

  test "returns posts ordered by last_comment_at descending" do
    older_post = Post.create!(title: "Older activity", content: "content", user: @user)
    newer_post = Post.create!(title: "Newer activity", content: "content", user: @user)
    older_post.comments.create!(content: "Old comment", user: @user, created_at: 2.hours.ago)
    newer_post.comments.create!(content: "New comment", user: @user)

    result = BackendSchema.execute(QUERY, context: { request: mock_request })
    ids = result["data"]["trendingPosts"].map { |p| p["id"] }

    assert ids.index(newer_post.id.to_s) < ids.index(older_post.id.to_s),
           "Expected post with more recent comment to appear first"
  ensure
    older_post.destroy
    newer_post.destroy
  end

  test "posts with no comments appear after posts with comments" do
    commented_post = Post.create!(title: "Has comments", content: "content", user: @user)
    silent_post    = Post.create!(title: "No comments",  content: "content", user: @user)
    commented_post.comments.create!(content: "A comment", user: @user)

    result = BackendSchema.execute(QUERY, context: { request: mock_request })
    ids = result["data"]["trendingPosts"].map { |p| p["id"] }

    assert ids.index(commented_post.id.to_s) < ids.index(silent_post.id.to_s),
           "Expected post with comments to appear before post with no comments"
  ensure
    commented_post.destroy
    silent_post.destroy
  end

  # — limit argument —

  test "returns 10 posts by default" do
    12.times { |i| Post.create!(title: "Post #{i}", content: "content", user: @user) }

    result = BackendSchema.execute(QUERY, context: { request: mock_request })

    assert result["data"]["trendingPosts"].length <= 10
  end

  test "respects the limit argument" do
    5.times { |i| Post.create!(title: "Post #{i}", content: "content", user: @user) }

    result = BackendSchema.execute("{ trendingPosts(limit: 3) { id } }", context: { request: mock_request })

    assert_equal 3, result["data"]["trendingPosts"].length
  end

  test "returns an error when limit is 0" do
    result = BackendSchema.execute("{ trendingPosts(limit: 0) { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "limit must be between", result["errors"].first["message"]
  end

  test "returns an error when limit exceeds maximum" do
    result = BackendSchema.execute("{ trendingPosts(limit: 21) { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "limit must be between", result["errors"].first["message"]
  end

  # — context / rate limiting —

  test "returns an error when request is missing from context" do
    result = BackendSchema.execute(QUERY, context: {})

    assert_not_nil result["errors"]
    assert_equal "Internal server error", result["errors"].first["message"]
  end

  test "returns an error when rate limit is exceeded" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    cache_key = "posts_request_127.0.0.1"
    Rails.cache.write(cache_key, Resolvers::TrendingPostResolver::RATE_LIMIT_MAX_REQUESTS + 1, expires_in: 1.hour)

    result = BackendSchema.execute(QUERY, context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "Rate limit exceeded", result["errors"].first["message"]
  ensure
    Rails.cache = original_cache
  end

  # — caching —

  test "caches results so a second request issues no post queries" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    BackendSchema.execute(QUERY, context: { request: mock_request })

    queries = count_queries do
      BackendSchema.execute(QUERY, context: { request: mock_request })
    end

    assert_equal 0, queries, "Expected 0 post queries on a cached trending request"
  ensure
    Rails.cache = original_cache
  end

  test "cache is invalidated when a new comment is created" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    BackendSchema.execute(QUERY, context: { request: mock_request })
    cached_keys_before = trending_cache_keys

    @post.comments.create!(content: "New comment", user: @user)

    cached_keys_after = trending_cache_keys
    assert cached_keys_after.empty? || cached_keys_before != cached_keys_after,
           "Expected trending cache to be invalidated after a new comment"
  ensure
    Rails.cache = original_cache
  end

  # — content filtering —

  test "censors profanity in post content" do
    profane_post = Post.create!(
      title: "Profane Post",
      content: "This contains bad_word1 in it",
      user: @user
    )
    profane_post.comments.create!(content: "A comment", user: @user)

    result = BackendSchema.execute("{ trendingPosts { id content } }", context: { request: mock_request })
    post_data = result["data"]["trendingPosts"].find { |p| p["id"] == profane_post.id.to_s }

    assert_not_nil post_data
    assert_includes post_data["content"], "*" * "bad_word1".length
    assert_not_includes post_data["content"], "bad_word1"
  ensure
    profane_post&.destroy
  end

  private

  def mock_request
    OpenStruct.new(remote_ip: "127.0.0.1")
  end

  def count_queries(&block)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) {
      count += 1 if payload[:name]&.end_with?(" Load")
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  def trending_cache_keys
    Rails.cache.instance_variable_get(:@data).keys.select { |k| k.include?("trending_posts") }
  end
end
