# frozen_string_literal: true

module Sources
  class CommentsSource < GraphQL::Dataloader::Source
    def initialize(limit:, offset:)
      @limit = limit
      @offset = offset
    end

    def fetch(post_ids)
      comments = Comment
        .where(post_id: post_ids)
        .includes(:user)
        .order(created_at: :desc)

      grouped = comments.group_by(&:post_id)
      post_ids.map { |id| (grouped[id] || [])[@offset, @limit] || [] }
    end
  end
end
