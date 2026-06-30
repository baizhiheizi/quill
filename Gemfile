# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> 4.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 8.1"

gem "pg"
gem "sqlite3"

# A performance dashboard for Postgres
gem "pghero"

# Use Puma as the app server
gem "puma"

# Deliver assets for Rails
gem "propshaft"

# Use Turbo in your Ruby on Rails app
gem "turbo-rails"

# Use Stimulus in your Ruby on Rails app
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Bundle and transpile JavaScript in Rails with esbuild, rollup.js, or Webpack.
gem "jsbundling-rails"

# Rails Request.JS encapsulates the logic to send by default some headers that are required by rails applications like the X-CSRF-Token
gem "requestjs-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"

# Use Active Model has_secure_password
gem "bcrypt"

# A simple API wrapper for Mixin Network in Ruby
gem "mixin_bot", "~> 2.0"

# A simple API wrapper for Pando in Ruby
gem "pando_bot"

# S3 active storage service
gem "aws-sdk-s3", require: false

# Use Active Storage variant
gem "image_processing", "~> 2.0"

# Modern rich text editor for Action Text
gem "lexxy", "~> 0.9.21"

# URI parsing and normalization (used for profile and payment URLs in production)
gem "addressable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Required on Ruby 4.0+ (no longer default gems)
gem "benchmark"
gem "cgi"
gem "mutex_m"
gem "tsort"

# AASM - State machines for Ruby classes (plain Ruby, ActiveRecord, Mongoid)
gem "aasm"

# Allows to use ActiveRecord transactional callbacks outside of ActiveRecord models, literally everywhere in your application.
gem "after_commit_everywhere"

# Store different kinds of actions (Like, Follow, Star, Block, etc.) in a single table via ActiveRecord Polymorphic Associations.
gem "action-store"

# The simplest way to group temporal data
gem "groupdate"

# Object-based searching. http://ransack-demo.herokuapp.com
gem "ransack"

# Ruby gem for reporting errors to honeybadger.io
# gem 'honeybadger', '~> 4.8'

# A simple, standardized way to build and use Service Objects (aka Commands) in Ruby
gem "simple_command"

# Notifications for Ruby on Rails applications
gem "noticed", "~> 3.0"

# Centralization of locale data collection for Ruby on Rails.
gem "rails-i18n"

# Add arbitrary ordering to ActiveRecord queries.
gem "order_as_specified"

# Rack middleware for blocking & throttling abusive requests
gem "rack-attack"

# The ultimate pagination ruby gem
gem "pagy"

# Rack Middleware for handling Cross-Origin Resource Sharing (CORS), which makes cross-origin AJAX possible.
gem "rack-cors"

# fnv1 and fnv1a hash functions in ruby
gem "fnv"

# Config helps you easily manage environment specific settings in an easy and usable manner.
gem "config"

# Makes http fun again!
gem "httparty"

# httprb client used by Mixpay::Client
gem "http"

# Tracking ⚠️ exceptions for Rails application and store them in database.
gem "exception-track"

# kramdown is a fast, pure Ruby Markdown superset converter, using a strict syntax definition and supporting several common extensions.
gem "kramdown"
gem "kramdown-parser-gfm"

# Easily include static pages in your Rails app.
gem "high_voltage"

# a straightforward library to build, sign, and broadcast ethereum transactions anywhere you can run ruby.
gem "eth"

# FastImage finds the size or type of an image given its uri by fetching as little as needed
gem "fastimage"

# compact language detection in ruby
gem "cld", github: "jtoy/cld"

# Enumerated attributes with I18n and ActiveRecord/Mongoid support
gem "enumerize"

# Mailjet official Ruby GEM#
gem "mailjet"

gem "inline_svg"

# Do some browser detection with Ruby. Includes ActionController integration.
gem "browser"

# A Ruby gem to transform HTML into PDFs, PNGs or JPEGs using Google Puppeteer/Chromium
gem "grover"

# A Ruby library that encodes QR Codes
gem "rqrcode"

# A Ruby library for declaring, composing and executing GraphQL queries
gem "graphql", "~> 2.0"

# Rails Plugin that tracks impressions and page views
gem "impressionist", github: "charlotte-ruby/impressionist"

# Twitter OAuth 2.0 Client Library in Ruby
gem "twitter_oauth2"

gem "solid_queue"
gem "mission_control-jobs"

gem "solid_cache", "~> 1.0"

group :development, :test do
  # Start debugger with binding.b [https://github.com/ruby/debug]
  gem "debug", ">= 1.0.0", platforms: %i[mri windows]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "listen", "~> 3.10"
  gem "web-console", ">= 3.3.0"
  # Annotate Rails classes with schema and routes info
  gem "annotaterb", require: false
  # A Ruby static code analyzer and formatter
  gem "kamal"
  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # Rails 7.1 test runner is incompatible with minitest 6 (pulled in on Ruby 4)
  gem "minitest", "~> 6.0"

  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver", ">= 4.11"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "mini_racer", platforms: :ruby
gem "tzinfo-data", platforms: %i[windows jruby]

gem "dockerfile-rails", ">= 1.2", group: :development

gem "solid_cable", "~> 4.0"

gem "pundit", "~> 2.5"

gem "ruby-vips", "~> 2.2"
