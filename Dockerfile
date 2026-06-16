# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=4.0.5
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT="1"

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to install nodejs and chrome
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libsqlite3-dev libvips libyaml-dev node-gyp pkg-config python-is-python3 redis automake libtool libffi-dev libssl-dev libgmp-dev python3-dev libsodium-dev unzip

# Install JavaScript dependencies
ARG NODE_VERSION=24.12.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
      "https://github.com/nodenv/node-build/archive/refs/heads/main.tar.gz" \
      -o /tmp/node-build.tgz && \
    tar xzf /tmp/node-build.tgz -C /tmp/ && \
    /tmp/node-build-main/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    rm -rf /tmp/node-build-main /tmp/node-build.tgz

# Install application gems
COPY --link Gemfile Gemfile.lock ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile && \
    rm -rf ~/.bundle/ $BUNDLE_PATH/ruby/*/cache $BUNDLE_PATH/ruby/*/bundler/gems/*/.git

# Install Bun for CSS/JS building
RUN curl -fsSL https://bun.sh/install | bash && \
    ln -s ~/.bun/bin/bun /usr/local/bin/bun

# Install node modules
COPY --link package.json bun.lock ./
RUN bun install --frozen-lockfile

# Copy application code
COPY --link . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production (test credentials are committed for CI/Docker builds)
RUN SECRET_KEY_BASE=DUMMY RAILS_ENV=test RAILS_MASTER_KEY="$(cat config/credentials/test.key)" ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y imagemagick librsvg2-bin libvips libyaml-0-2 postgresql-client redis libsodium-dev curl ffmpeg libsqlite3-0 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Run and own the application files as a non-root user for security
RUN useradd rails --home /rails --shell /bin/bash
USER rails:rails

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

# Deployment options
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" 

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/rails", "server"]
