# frozen_string_literal: true

# Users are authors of posts and comments.
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments
end
