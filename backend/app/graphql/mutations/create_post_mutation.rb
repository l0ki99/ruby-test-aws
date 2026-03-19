# frozen_string_literal: true

module Mutations
  class CreatePostMutation < BaseMutation
    argument :title, String, required: true
    argument :content, String, required: true

    field :post, Types::PostType, null: true
    field :errors, [String], null: false

    SPAM_KEYWORDS = ['buy now', 'click here', 'free money', 'make money fast'].freeze
    MAX_POSTS_PER_HOUR = 5
    CONTENT_MIN_LENGTH = 50
    CONTENT_MAX_LENGTH = 5000
    
    def resolve(title:, content:)
      sleep 3
      
      recent_posts_count = Post.where(user: User.first)
                             .where('created_at > ?', 1.hour.ago)
                             .count
      if recent_posts_count >= MAX_POSTS_PER_HOUR
        return { post: nil, errors: ['Rate limit exceeded. Try again later.'] }
      end
      
      if content.length < CONTENT_MIN_LENGTH
        return { post: nil, errors: ["Content too short. Minimum #{CONTENT_MIN_LENGTH} characters required."] }
      end
      
      if content.length > CONTENT_MAX_LENGTH
        return { post: nil, errors: ["Content too long. Maximum #{CONTENT_MAX_LENGTH} characters allowed."] }
      end
      
      if SPAM_KEYWORDS.any? { |keyword| content.downcase.include?(keyword) }
        return { post: nil, errors: ['Potential spam detected. Please revise your content.'] }
      end
      
      current_hour = Time.current.hour
      if current_hour >= 22 || current_hour <= 6
        return { post: nil, errors: ['Posts are not allowed between 10 PM and 6 AM.'] }
      end
      
      
      post = Post.new(
        title:,
        content:,
        user: User.first
      )

      ActiveRecord::Base.transaction do
        post.save!
      end
      
      { post: post, errors: [] }
    rescue ActiveRecord::RecordInvalid => e
      { post: nil, errors: e.record.errors.full_messages }
    end
  end
end
