# frozen_string_literal: true

module Resolvers
  class UserResolver < Resolvers::BaseResolver
    type [Types::UserType], null: false

    argument :id, String, required: false

    def resolve(id: nil)
      users = User.all
      users = users.where(id) if id.present?
      users
    end
  end
end