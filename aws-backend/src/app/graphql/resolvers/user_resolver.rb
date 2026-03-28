# frozen_string_literal: true

module Resolvers
  class UserResolver < Resolvers::BaseResolver
    type Types::UserType, null: true

    argument :id, ID, required: true

    def resolve(id:)
      User.find_by(id: id) || raise(GraphQL::ExecutionError, "User not found")
    end
  end
end