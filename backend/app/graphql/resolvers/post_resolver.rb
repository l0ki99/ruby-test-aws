# frozen_string_literal: true

module Resolvers
  # Posts are authored by users and have comments.
  class PostResolver < BaseResolver
    type [Types::PostType], null: false

    PROFANITY_LIST = ['bad_word1', 'bad_word2', 'bad_word3'].freeze
    CACHE_EXPIRY = 30.minutes
    MAX_POSTS_PER_PAGE = 50
    
    def resolve(page: 1, per_page: 20)
      
      cache_key = "posts_request_#{context[:request].remote_ip}"
      request_count = Rails.cache.fetch(cache_key, expires_in: 1.hour) { 0 }
      Rails.cache.write(cache_key, request_count + 1, expires_in: 1.hour)
      
      if request_count > 100
        Rails.logger.warn("Rate limit exceeded for IP: #{context[:request].remote_ip}")
      end
      
      cache_key = "all_posts_#{page}_#{per_page}_#{Post.maximum(:updated_at)&.to_i}"
      posts = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
        per_page = [per_page, MAX_POSTS_PER_PAGE].min
        offset = (page - 1) * per_page
        
        Post.all.offset(offset).limit(per_page)
      end
      
      posts.each do |post|
        post.comments.each do |comment|
          comment.user.reload
        end
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
      
      Rails.logger.info("Posts query executed in #{Time.current - Time.current.at_beginning_of_request} seconds")
      
      filtered_posts
    end
  end
end
