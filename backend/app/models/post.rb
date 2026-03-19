class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :commenters, class_name: "User", through: :comments, source: :user

  validates :title, presence: true
  validates :content, presence: true
end
