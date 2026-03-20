# frozen_string_literal: true

module Resolvers
  # Posts are authored by users and have comments.
  class PostResolver < BaseResolver
    type [Types::PostType], null: false

    PROFANITY_LIST = ['bad_word1', 'bad_word2', 'bad_word3'].freeze
    CACHE_EXPIRY = 30.minutes
    MAX_POSTS_PER_PAGE = 50
    RATE_LIMIT_MAX_REQUESTS = 100

    argument :page, Integer, required: false, default_value: 1
    argument :per_page, Integer, required: false, default_value: 20

    def resolve(page:, per_page:)
      unless context[:request]
        Rails.logger.error("PostResolver: request missing from GraphQL context")
        raise GraphQL::ExecutionError, "Internal server error"
      end
      raise GraphQL::ExecutionError, "page must be >= 1" if page < 1
      raise GraphQL::ExecutionError, "per_page must be between 1 and #{MAX_POSTS_PER_PAGE}" unless (1..MAX_POSTS_PER_PAGE).cover?(per_page)

      started_at = Time.current

      cache_key = "posts_request_#{context[:request].remote_ip}"
      request_count = Rails.cache.fetch(cache_key, expires_in: 1.hour) { 0 }
      Rails.cache.write(cache_key, request_count + 1, expires_in: 1.hour)

      if request_count > RATE_LIMIT_MAX_REQUESTS
        Rails.logger.warn("Rate limit exceeded for IP: #{context[:request].remote_ip}")
        raise GraphQL::ExecutionError, "Rate limit exceeded. Try again later."
      end

      clamped_per_page = [per_page, MAX_POSTS_PER_PAGE].min
      cache_key = "all_posts_#{page}_#{clamped_per_page}_#{Post.maximum(:updated_at)&.to_i}"
      posts = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
        offset = (page - 1) * clamped_per_page

        Post.includes(comments: :user).offset(offset).limit(clamped_per_page).to_a
      end

      filtered_posts = posts.map do |post|
        censored_content = post.content.dup
        PROFANITY_LIST.each do |word|
          censored_content.gsub!(/#{word}/i, '*' * word.length) if censored_content.include?(word)
        end
        post.content = censored_content
        
        word_count = post.content.split.size
        reading_minutes = (word_count / 200.0).ceil
        post.define_singleton_method(:reading_time) do
          "#{reading_minutes} min read"
        end
        
        post
      end
      
      Rails.logger.info("Posts query executed in #{Time.current - started_at} seconds")
      
      filtered_posts
    end
  end
end
