# frozen_string_literal: true

require 'sidekiq/throttled'

Redis.sadd_returns_boolean = true

Sidekiq.configure_server do |config|
  config.redis = { namespace: Rails.application.credentials.dig(:sidekiq, :namespace) || 'quill_sidekiq' }

  cron_file = 'config/sidekiq-cron.yml'
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(cron_file) if File.exist?(cron_file) && Sidekiq.server?
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: Rails.application.credentials.dig(:sidekiq, :namespace) || 'quill_sidekiq' }
end

Sidekiq::Throttled.setup!
Sidekiq.strict_args!
