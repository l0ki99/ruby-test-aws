# frozen_string_literal: true

module Types
  class PostSortEnum < Types::BaseEnum
    value "NEWEST", "Sort by creation date, newest first"
    value "OLDEST", "Sort by creation date, oldest first"
    value "AUTHOR_AZ", "Sort by author name, A to Z"
    value "AUTHOR_ZA", "Sort by author name, Z to A"
  end
end
