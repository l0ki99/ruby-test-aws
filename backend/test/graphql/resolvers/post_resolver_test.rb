require "test_helper"
require "ostruct"

class Resolvers::PostResolverTest < ActiveSupport::TestCase
  QUERY = <<~GQL
    { posts { id comments { id author { id } } } }
  GQL

  def setup
    @user = User.create!(email: "resolver_test@example.com", name: "resolveruser")
    @post = Post.create!(title: "Test post", content: "Some content", user: @user)
    @comment = @post.comments.create!(content: "A comment", user: @user)
    Rails.cache.clear
  end

  def teardown
    @user.destroy
    Rails.cache.clear
  end

  # Count only model load queries (e.g. "Post Load", "Comment Load").
  # Ignores PRAGMA, schema introspection, and transaction statements.
  def count_queries(&block)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) {
      count += 1 if payload[:name]&.end_with?(" Load")
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  test "returns posts with their comments and comment authors" do
    result = BackendSchema.execute(QUERY, context: { request: mock_request })
    post_data = result["data"]["posts"].find { |p| p["id"] == @post.id.to_s }

    assert_not_nil post_data
    comment_data = post_data["comments"].find { |c| c["id"] == @comment.id.to_s }
    assert_not_nil comment_data
    assert_equal @user.id.to_s, comment_data["author"]["id"]
  end

  test "fetches posts and all associations in a fixed number of queries" do
    extra_user = User.create!(email: "other@example.com", name: "other")
    extra_post = Post.create!(title: "Post 2", content: "More content", user: extra_user)
    extra_post.comments.create!(content: "Comment", user: extra_user)

    queries = count_queries do
      BackendSchema.execute(QUERY, context: { request: mock_request })
    end

    # Expect exactly 3 load queries: posts, comments, users.
    assert queries <= 3, "Expected at most 3 load queries, got #{queries}. Possible N+1."
  ensure
    extra_user.destroy
  end

  test "caches results so a second request issues no additional post/comment queries" do
    # The test environment uses NullStore by default, so we swap in a real cache.
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # Prime the cache.
    BackendSchema.execute(QUERY, context: { request: mock_request })

    queries_second_request = count_queries do
      BackendSchema.execute(QUERY, context: { request: mock_request })
    end

    # After the cache is warm, no model loads should occur — associations are
    # serialized with the cached records.
    assert_equal 0, queries_second_request,
                 "Expected 0 load queries on a cached request, got #{queries_second_request}."
  ensure
    Rails.cache = original_cache
  end

  test "succeeds when request is present in context" do
    result = BackendSchema.execute("{ posts { id } }", context: { request: mock_request })

    assert_nil result["errors"]
    assert_kind_of Array, result["data"]["posts"]
  end

  test "returns an error when request is missing from context" do
    result = BackendSchema.execute("{ posts { id } }", context: {})

    assert_not_nil result["errors"]
    assert_equal "Internal server error", result["errors"].first["message"]
    assert_nil result["data"]
  end

  test "returns an error when page is less than 1" do
    result = BackendSchema.execute("{ posts(page: 0) { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "page must be >= 1", result["errors"].first["message"]
  end

  test "returns an error when per_page is 0" do
    result = BackendSchema.execute("{ posts(perPage: 0) { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "per_page must be between", result["errors"].first["message"]
  end

  test "returns an error when per_page exceeds maximum" do
    result = BackendSchema.execute("{ posts(perPage: 51) { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "per_page must be between", result["errors"].first["message"]
  end

  test "accepts valid page and per_page arguments" do
    result = BackendSchema.execute("{ posts(page: 1, perPage: 10) { id } }", context: { request: mock_request })

    assert_nil result["errors"]
    assert_kind_of Array, result["data"]["posts"]
  end

  test "returns an error when rate limit is exceeded" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    cache_key = "posts_request_127.0.0.1"
    Rails.cache.write(cache_key, Resolvers::PostResolver::RATE_LIMIT_MAX_REQUESTS + 1, expires_in: 1.hour)

    result = BackendSchema.execute("{ posts { id } }", context: { request: mock_request })

    assert_not_nil result["errors"]
    assert_match "Rate limit exceeded", result["errors"].first["message"]
  ensure
    Rails.cache = original_cache
  end

  test "repeated requests with the same per_page share a cache entry" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    BackendSchema.execute("{ posts(perPage: 50) { id } }", context: { request: mock_request })

    queries = count_queries do
      BackendSchema.execute("{ posts(perPage: 50) { id } }", context: { request: mock_request })
    end

    assert_equal 0, queries, "Expected cache hit on second request with same per_page"
  ensure
    Rails.cache = original_cache
  end

  test "returns posts sorted by NEWEST (created_at desc) by default" do
    older_post = Post.create!(title: "Older", content: "content", user: @user, created_at: 2.days.ago)
    newer_post = Post.create!(title: "Newer", content: "content", user: @user, created_at: 1.day.ago)

    result = BackendSchema.execute("{ posts { id } }", context: { request: mock_request })
    ids = result["data"]["posts"].map { |p| p["id"] }

    assert ids.index(newer_post.id.to_s) < ids.index(older_post.id.to_s),
           "Expected newer post before older post with NEWEST sort"
  ensure
    older_post.destroy
    newer_post.destroy
  end

  test "returns posts sorted by OLDEST (created_at asc)" do
    older_post = Post.create!(title: "Older", content: "content", user: @user, created_at: 2.days.ago)
    newer_post = Post.create!(title: "Newer", content: "content", user: @user, created_at: 1.day.ago)

    result = BackendSchema.execute('{ posts(sortBy: OLDEST) { id } }', context: { request: mock_request })
    ids = result["data"]["posts"].map { |p| p["id"] }

    assert ids.index(older_post.id.to_s) < ids.index(newer_post.id.to_s),
           "Expected older post before newer post with OLDEST sort"
  ensure
    older_post.destroy
    newer_post.destroy
  end

  test "returns posts sorted by AUTHOR_AZ (author name asc)" do
    user_z = User.create!(email: "z@example.com", name: "Zara")
    user_a = User.create!(email: "a@example.com", name: "Aaron")
    post_z = Post.create!(title: "Zara's Post", content: "content", user: user_z)
    post_a = Post.create!(title: "Aaron's Post", content: "content", user: user_a)

    result = BackendSchema.execute('{ posts(sortBy: AUTHOR_AZ) { id } }', context: { request: mock_request })
    ids = result["data"]["posts"].map { |p| p["id"] }

    assert ids.index(post_a.id.to_s) < ids.index(post_z.id.to_s),
           "Expected Aaron's post before Zara's post with AUTHOR_AZ sort"
  ensure
    post_z.destroy
    post_a.destroy
    user_z.destroy
    user_a.destroy
  end

  test "returns posts sorted by AUTHOR_ZA (author name desc)" do
    user_z = User.create!(email: "z2@example.com", name: "Zara")
    user_a = User.create!(email: "a2@example.com", name: "Aaron")
    post_z = Post.create!(title: "Zara's Post", content: "content", user: user_z)
    post_a = Post.create!(title: "Aaron's Post", content: "content", user: user_a)

    result = BackendSchema.execute('{ posts(sortBy: AUTHOR_ZA) { id } }', context: { request: mock_request })
    ids = result["data"]["posts"].map { |p| p["id"] }

    assert ids.index(post_z.id.to_s) < ids.index(post_a.id.to_s),
           "Expected Zara's post before Aaron's post with AUTHOR_ZA sort"
  ensure
    post_z.destroy
    post_a.destroy
    user_z.destroy
    user_a.destroy
  end

  test "sort_by is included in the cache key so different sorts are cached separately" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    BackendSchema.execute('{ posts(sortBy: NEWEST) { id } }', context: { request: mock_request })
    BackendSchema.execute('{ posts(sortBy: OLDEST) { id } }', context: { request: mock_request })

    newest_key = Rails.cache.instance_variable_get(:@data).keys.find { |k| k.include?("NEWEST") }
    oldest_key = Rails.cache.instance_variable_get(:@data).keys.find { |k| k.include?("OLDEST") }

    assert_not_nil newest_key, "Expected a cache entry for NEWEST sort"
    assert_not_nil oldest_key, "Expected a cache entry for OLDEST sort"
  ensure
    Rails.cache = original_cache
  end

  private

  def mock_request
    OpenStruct.new(remote_ip: "127.0.0.1")
  end
end
