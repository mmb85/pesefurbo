# Use official Ruby image
FROM ruby:3.4-slim

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  git \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install --no-cache

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Run entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-c", "config/puma.rb"]
