# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class CreatePostMutationTest < ActiveSupport::TestCase
  MUTATION = <<~GQL
    mutation CreatePost($title: String!, $content: String!) {
      createPost(input: { title: $title, content: $content }) {
        post { id }
        errors
      }
    }
  GQL

  VALID_CONTENT = "A" * 50

  def setup
    @user = User.create!(email: "mutation_test@example.com", name: "mutationuser")
  end

  def teardown
    @user.destroy
  end

  test "returns a controlled error when title is blank" do
    result = BackendSchema.execute(MUTATION, variables: { title: "", content: VALID_CONTENT })
    errors = result.dig("data", "createPost", "errors")

    assert_equal ["Title can't be blank"], errors
  end

  test "returns a controlled error when content is blank" do
    result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: "" })
    errors = result.dig("data", "createPost", "errors")

    assert_includes errors, "Content can't be blank"
  end

  test "returns both controlled errors when title and content are blank" do
    result = BackendSchema.execute(MUTATION, variables: { title: "", content: "" })
    errors = result.dig("data", "createPost", "errors")

    assert_includes errors, "Title can't be blank"
    assert_includes errors, "Content can't be blank"
  end

  test "does not leak model internals when no user exists" do
    User.stub(:first, nil) do
      result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: VALID_CONTENT })
      errors = result.dig("data", "createPost", "errors")

      assert errors.none? { |e| e.match?(/user|must exist|activerecord/i) },
             "Error leaks internal model details: #{errors}"
      assert_equal ["Unable to create post. Please try again."], errors
    end
  end

  test "returns a generic error and no model details when save fails unexpectedly" do
    invalid_post = Post.new # created before stub is applied
    Post.stub(:new, -> (*) { raise ActiveRecord::RecordInvalid.new(invalid_post) }) do
      result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: VALID_CONTENT })
      errors = result.dig("data", "createPost", "errors")

      assert_equal ["Unable to create post. Please try again."], errors
    end
  end

  test "returns an error when content is below minimum length" do
    short_content = "A" * (Mutations::CreatePostMutation::CONTENT_MIN_LENGTH - 1)
    result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: short_content })
    errors = result.dig("data", "createPost", "errors")

    assert_includes errors.first, "Content too short"
  end

  test "returns an error when content exceeds maximum length" do
    long_content = "A" * (Mutations::CreatePostMutation::CONTENT_MAX_LENGTH + 1)
    result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: long_content })
    errors = result.dig("data", "createPost", "errors")

    assert_includes errors.first, "Content too long"
  end

  test "returns an error when content contains spam keywords" do
    spammy_content = "A" * 40 + " click here to win"
    result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: spammy_content })
    errors = result.dig("data", "createPost", "errors")

    assert_includes errors.first, "spam"
  end

  test "returns an error when rate limit is exceeded" do
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    Post.stub(:where, ->(*) {
      obj = Object.new
      obj.define_singleton_method(:where) { |*| obj }
      obj.define_singleton_method(:count) { Mutations::CreatePostMutation::MAX_POSTS_PER_HOUR }
      obj
    }) do
      result = BackendSchema.execute(MUTATION, variables: { title: "My Post", content: VALID_CONTENT })
      errors = result.dig("data", "createPost", "errors")

      assert_includes errors.first, "Rate limit exceeded"
    end
  ensure
    Rails.cache = original_cache
  end
end
