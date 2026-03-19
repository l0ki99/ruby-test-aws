# frozen_string_literal: true

module Types
  # Comments belong to a post, and are authored by a user.
  class CommentType < Types::BaseObject
    field :id, ID, null: false
    field :post, [Types::PostType], null: false
    field :author, [Types::UserType], null: false
    field :content, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end