class Comment < ApplicationRecord
  belongs_to :post, counter_cache: :comment_counter
  belongs_to :user
end
