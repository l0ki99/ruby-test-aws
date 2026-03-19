class AddCommentCounterToPosts < ActiveRecord::Migration[7.0]
  def up
    add_column :posts, :comment_counter, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE posts
      SET comment_counter = (
        SELECT COUNT(*) FROM comments WHERE comments.post_id = posts.id
      )
    SQL
  end

  def down
    remove_column :posts, :comment_counter
  end
end
