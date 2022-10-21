# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7'

# Use pg as the database for Active Record
gem 'pg'

# A performance dashboard for Postgres
gem 'pghero'

# Use Puma as the app server
gem 'puma'

# Deliver assets for Rails
gem 'propshaft'

# Use Turbo in your Ruby on Rails app
gem 'turbo-rails'

# Use Stimulus in your Ruby on Rails app
gem 'stimulus-rails'

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem 'cssbundling-rails'

# Bundle and transpile JavaScript in Rails with esbuild, rollup.js, or Webpack.
gem 'jsbundling-rails'

# Rails Request.JS encapsulates the logic to send by default some headers that are required by rails applications like the X-CSRF-Token
gem 'requestjs-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'hiredis'
gem 'redis'

# Map Redis types directly to Ruby objects
gem 'redis-objects'

# This gem adds a Redis::Namespace class which can be used to namespace Redis keys. http://redis.io
gem 'redis-namespace'

# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

# A simple API wrapper for Mixin Network in Ruby
gem 'mixin_bot'

# A simple API wrapper for Trident in Ruby
gem 'trident_assistant', git: 'https://github.com/TheTridentOne/trident_assistant.git'

# Wraps the Aliyun OSS as an Active Storage service.
gem 'activestorage-aliyun'

# S3 active storage service
gem 'aws-sdk-s3', require: false

# Simple, efficient background processing for Ruby http://sidekiq.org
gem 'sidekiq', '~> 6.0'

# Scheduler / Cron for Sidekiq jobs
gem 'sidekiq-cron'

# Concurrency and threshold throttling for Sidekiq.
gem 'sidekiq-throttled'

# Use Active Storage variant
gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

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

# Ruby gem for reporting errors to honeybadger.io
# gem 'honeybadger', '~> 4.8'

# A simple, standardized way to build and use Service Objects (aka Commands) in Ruby
gem 'simple_command'

# Notifications for Ruby on Rails applications
gem 'noticed'

# Centralization of locale data collection for Ruby on Rails.
gem 'rails-i18n'

# Add arbitrary ordering to ActiveRecord queries.
gem 'order_as_specified'

# Rack middleware for blocking & throttling abusive requests
gem 'rack-attack'

# The ultimate pagination ruby gem
gem 'pagy'

# Rack Middleware for handling Cross-Origin Resource Sharing (CORS), which makes cross-origin AJAX possible.
gem 'rack-cors'

# fnv1 and fnv1a hash functions in ruby
gem 'fnv'

# Config helps you easily manage environment specific settings in an easy and usable manner.
gem 'config'

# Makes http fun again!
gem 'httparty'

# Tracking ⚠️ exceptions for Rails application and store them in database.
gem 'exception-track'

# The safe Markdown parser, reloaded.
gem 'redcarpet'

# Easily include static pages in your Rails app.
gem 'high_voltage'

# a straightforward library to build, sign, and broadcast ethereum transactions anywhere you can run ruby.
gem 'eth'

# FastImage finds the size or type of an image given its uri by fetching as little as needed
gem 'fastimage'

# compact language detection in ruby
gem 'cld'

# Enumerated attributes with I18n and ActiveRecord/Mongoid support
gem 'enumerize'

# A framework for building reusable, testable & encapsulated view components in Ruby on Rails.
gem 'view_component'

# Saves your data permanent and let your customers own their data.
gem 'arweave', github: 'baizhiheizi/arweave-ruby'

# Mailjet official Ruby GEM#
gem 'mailjet'

gem 'inline_svg'

# Do some browser detection with Ruby. Includes ActionController integration.
gem 'browser'

# Write Through and Read Through caching library inspired by CacheMoney and cache_fu.
gem 'second_level_cache'

# deploy
gem 'mina', '~> 1.2.2', require: false
gem 'mina-logs', '~> 1.1.0', require: false
gem 'mina-multistage', '~> 1.0.3', require: false

group :development, :test do
  # Start debugger with binding.b [https://github.com/ruby/debug]
  gem 'debug', '>= 1.0.0', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '~> 3.4'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.1.0'
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
gem 'mini_racer', platforms: :ruby
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
