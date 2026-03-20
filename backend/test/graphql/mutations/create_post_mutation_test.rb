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
end
