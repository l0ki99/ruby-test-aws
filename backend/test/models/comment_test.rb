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

  def teardown
    @user.destroy
  end
end
