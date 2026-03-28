# frozen_string_literal: true

module Resolvers
  # Returns posts ordered by most recent comment activity.
  class TrendingPostResolver < BaseResolver
    type [Types::PostType], null: false

    PROFANITY_LIST = ['bad_word1', 'bad_word2', 'bad_word3'].freeze
    CACHE_EXPIRY = 5.minutes
    MAX_LIMIT = 20
    RATE_LIMIT_MAX_REQUESTS = 100

    argument :limit, Integer, required: false, default_value: 10

    def resolve(limit:)
      unless context[:request]
        Rails.logger.error("TrendingPostResolver: request missing from GraphQL context")
        raise GraphQL::ExecutionError, "Internal server error"
      end
      raise GraphQL::ExecutionError, "limit must be between 1 and #{MAX_LIMIT}" unless (1..MAX_LIMIT).cover?(limit)

      cache_key = "posts_request_#{context[:request].remote_ip}"
      request_count = Rails.cache.fetch(cache_key, expires_in: 1.hour) { 0 }
      Rails.cache.write(cache_key, request_count + 1, expires_in: 1.hour)

      if request_count > RATE_LIMIT_MAX_REQUESTS
        Rails.logger.warn("Rate limit exceeded for IP: #{context[:request].remote_ip}")
        raise GraphQL::ExecutionError, "Rate limit exceeded. Try again later."
      end

      version = Rails.cache.fetch("trending_posts_cache_version") { Time.current.to_i }
      posts = Rails.cache.fetch("trending_posts_#{limit}_#{version}", expires_in: CACHE_EXPIRY) do
        Post.order(Arel.sql("last_comment_at DESC NULLS LAST")).limit(limit).to_a
      end

      posts.map do |post|
        censored_content = post.content.dup
        PROFANITY_LIST.each do |word|
          censored_content.gsub!(/#{word}/i, '*' * word.length) if censored_content.include?(word)
        end

        presented = post.dup
        presented.id = post.id
        presented.content = censored_content
        presented.readonly!
        presented
      end
    end
  end
end
