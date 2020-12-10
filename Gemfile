# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6'
# Use pg as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.1'
# Map Redis types directly to Ruby objects
gem 'redis-objects'
# This gem adds a Redis::Namespace class which can be used to namespace Redis keys. http://redis.io
gem 'redis-namespace'
# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'
# A simple API wrapper for Mixin Network in Ruby
gem 'mixin_bot'
# Wraps the Aliyun OSS as an Active Storage service.
gem 'activestorage-aliyun'
# Simple, efficient background processing for Ruby http://sidekiq.org
gem 'sidekiq', '~> 6.0'
# Scheduler / Cron for Sidekiq jobs
gem 'sidekiq-cron'
# Use Active Storage variant
gem 'image_processing', '~> 1.2'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false
# Integrate React.js with Rails views and controllers, the asset pipeline, or webpacker. https://github.com/reactjs/react-rails
gem 'react-rails'
# Ruby implementation of GraphQL http://graphql-ruby.org
gem 'graphql'
# Mount the GraphiQL query editor in a Rails app
gem 'graphiql-rails'
# Powerful tool for avoiding N+1 DB or HTTP queries
gem 'batch-loader'
# AASM - State machines for Ruby classes (plain Ruby, ActiveRecord, Mongoid)
gem 'aasm'
# Allows to use ActiveRecord transactional callbacks outside of ActiveRecord models, literally everywhere in your application.
gem 'after_commit_everywhere'
# Store different kinds of actions (Like, Follow, Star, Block, etc.) in a single table via ActiveRecord Polymorphic Associations.
gem 'action-store'
# The simplest way to group temporal data
gem 'groupdate'
# Object-based searching. http://ransack-demo.herokuapp.com
gem 'ransack'

# deploy
gem 'mina', '~> 1.2.2', require: false
gem 'mina-logs', '~> 1.1.0', require: false
gem 'mina-multistage', '~> 1.0.3', require: false
# gem 'mina-sidekiq', '~> 1.0.3', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '~> 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Annotate Rails classes with schema and routes info
  gem 'annotate', require: false
  # A Ruby static code analyzer and formatter
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
