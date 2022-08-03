# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'pagy/extras/countless'
require 'pagy/extras/overflow'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Quill
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_job.queue_adapter = :sidekiq

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = Settings.time_zone if Settings.time_zone.present?
    config.i18n.available_locales = Settings.available_locales || %i[en]
    config.i18n.default_locale = Settings.default_locale || :en

    # custom error pages
    config.exceptions_app = routes

    # reference:
    # https://stackoverflow.com/questions/49233769/is-there-a-way-to-prevent-safari-on-ios-from-clearing-the-cookies-for-a-website
    # https://developer.mozilla.org/en-US/docs/Web/API/Document/cookie#Example_4_Reset_the_previous_cookie
    # https://api.rubyonrails.org/v5.2.1/classes/ActionDispatch/Session/CookieStore.html
    config.session_store :cookie_store, expire_after: 7.days, key: '_quill_session'
  end
end
