# backend/Dockerfile
FROM ruby:3.3.6

# Install development tools and other dependencies
RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev nodejs libxml2-dev libxslt-dev

# Set working directory
WORKDIR /backend

# Copy Gemfile and Gemfile.lock
COPY Gemfile* ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Clean up tmp directory
RUN rm -rf tmp/*

# Expose port 8090
EXPOSE 8090

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]