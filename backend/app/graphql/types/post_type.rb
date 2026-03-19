# frozen_string_literal: true

module Types
  # Posts are authored by a user.
  class PostType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :content, String, null: false
    field :image_url, String, null: true
    field :comment_counter, Integer, null: false
    field :comments, [Types::CommentType], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
