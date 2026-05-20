# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "grover"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Quill
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "UTC"
    config.i18n.available_locales = %i[en zh-CN ja]
    config.i18n.default_locale = :en

    config.exceptions_app = routes

    config.session_store :cookie_store, expire_after: 3.days, key: "_quill_sessions", domain: :all, httponly: true

    config.view_component.generate_parent_component = "ApplicationComponent"

    config.action_view.image_loading = "lazy"

    config.action_mailer.delivery_method = :mailjet

    config.active_record.yaml_column_permitted_classes = [ ActiveSupport::HashWithIndifferentAccess, Symbol ]

    config.middleware.use Grover::Middleware
  end
end
