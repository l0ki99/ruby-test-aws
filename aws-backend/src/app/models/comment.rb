class Comment < ApplicationRecord
  belongs_to :post, counter_cache: :comment_counter
  belongs_to :user

  after_create  :update_post_last_comment_at, :bust_trending_cache
  after_destroy :update_post_last_comment_at, :bust_trending_cache

  private

  def update_post_last_comment_at
    return if post.destroyed?

    post.update_column(:last_comment_at, post.comments.maximum(:created_at))
  end

  def bust_trending_cache
    Rails.cache.delete("trending_posts_cache_version")
  end
end
