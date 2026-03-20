class AddIndexToCommentsByPostIdAndCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :comments, [:post_id, :created_at]
  end
end
