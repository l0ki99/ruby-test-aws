class AddLastCommentAtToPosts < ActiveRecord::Migration[7.0]
  def up
    add_column :posts, :last_comment_at, :datetime

    Post.find_each do |post|
      post.update_column(:last_comment_at, post.comments.maximum(:created_at))
    end
  end

  def down
    remove_column :posts, :last_comment_at
  end
end
