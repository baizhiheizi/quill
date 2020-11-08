# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Prsdigg
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # react-rails
    config.react.camelize_props = true

    # reference:
    # https://stackoverflow.com/questions/49233769/is-there-a-way-to-prevent-safari-on-ios-from-clearing-the-cookies-for-a-website
    # https://developer.mozilla.org/en-US/docs/Web/API/Document/cookie#Example_4_Reset_the_previous_cookie
    # https://api.rubyonrails.org/v5.2.1/classes/ActionDispatch/Session/CookieStore.html
    config.session_store :cookie_store, expire_after: 14.days

    # https://github.com/exAspArk/batch-loader#caching
    config.middleware.use BatchLoader::Middleware
  end
end
