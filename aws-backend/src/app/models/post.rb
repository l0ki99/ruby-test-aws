class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :commenters, class_name: "User", through: :comments, source: :user

  validates :title, presence: true
  validates :content, presence: true

  after_save :bust_posts_cache

  private

  def bust_posts_cache
    Rails.cache.delete("posts_cache_version")
  end
end
