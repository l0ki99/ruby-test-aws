# frozen_string_literal: true

require "test_helper"

class Sources::CommentsSourceTest < ActiveSupport::TestCase
  def setup
    @user  = User.create!(email: "source_test@example.com", name: "sourceuser")
    @post  = Post.create!(title: "Post", content: "Content", user: @user)
    @post2 = Post.create!(title: "Post 2", content: "Content 2", user: @user)
  end

  def teardown
    @user.destroy
  end

  def count_queries(&block)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) {
      count += 1 if payload[:name]&.end_with?(" Load")
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  def source(limit: 20, offset: 0)
    Sources::CommentsSource.new(limit: limit, offset: offset)
  end

  test "returns comments for the given post" do
    comment = @post.comments.create!(content: "Hello", user: @user)

    results = source.fetch([@post.id])

    assert_equal 1, results.length
    assert_equal [comment.id], results.first.map(&:id)
  end

  test "returns empty array for a post with no comments" do
    results = source.fetch([@post.id])

    assert_equal [[]], results
  end

  test "returns results in newest-first order" do
    first  = @post.comments.create!(content: "First",  user: @user)
    second = @post.comments.create!(content: "Second", user: @user)

    results = source.fetch([@post.id]).first

    assert_equal [second.id, first.id], results.map(&:id)
  end

  test "applies limit" do
    5.times { |i| @post.comments.create!(content: "Comment #{i}", user: @user) }

    results = source(limit: 3).fetch([@post.id]).first

    assert_equal 3, results.length
  end

  test "applies offset" do
    3.times { |i| @post.comments.create!(content: "Comment #{i}", user: @user) }
    all_ids = @post.comments.order(created_at: :desc).pluck(:id)

    results = source(limit: 2, offset: 1).fetch([@post.id]).first

    assert_equal all_ids[1..2], results.map(&:id)
  end

  test "batches multiple post IDs in a single query" do
    @post.comments.create!(content:  "On post 1", user: @user)
    @post2.comments.create!(content: "On post 2", user: @user)

    queries = count_queries do
      source.fetch([@post.id, @post2.id])
    end

    # One Comment Load + one User Load (via includes) — never one query per post.
    assert queries <= 2, "Expected at most 2 queries for 2 posts, got #{queries}."
  end

  test "returns results in the same order as the given post IDs" do
    @post.comments.create!(content:  "Comment A", user: @user)
    @post2.comments.create!(content: "Comment B", user: @user)

    results = source.fetch([@post2.id, @post.id])

    assert_equal @post2.id, results[0].first.post_id
    assert_equal @post.id,  results[1].first.post_id
  end

  test "preloads comment authors to avoid N+1 on author access" do
    other_user = User.create!(email: "other@example.com", name: "Other")
    @post.comments.create!(content: "By other", user: other_user)
    @post.comments.create!(content: "By self",  user: @user)

    results = source.fetch([@post.id]).first

    queries = count_queries do
      results.each { |c| c.user.id }
    end

    assert_equal 0, queries, "Expected 0 queries accessing authors — should be preloaded."
  ensure
    other_user&.comments&.destroy_all
    other_user&.destroy
  end
end
