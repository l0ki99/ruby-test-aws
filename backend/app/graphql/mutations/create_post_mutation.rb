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
      
      input_errors = []
      input_errors << "Title can't be blank" if title.blank?
      input_errors << "Content can't be blank" if content.blank?
      return { post: nil, errors: input_errors } if input_errors.any?

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
      
      
      user = User.first
      return { post: nil, errors: ["Unable to create post. Please try again."] } if user.nil?

      post = Post.new(title:, content:, user:)

      ActiveRecord::Base.transaction do
        post.save!
      end

      { post: post, errors: [] }
    rescue ActiveRecord::RecordInvalid
      { post: nil, errors: ["Unable to create post. Please try again."] }
    end
  end
end
