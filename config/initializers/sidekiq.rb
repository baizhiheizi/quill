# frozen_string_literal: true

require 'sidekiq/throttled'

Sidekiq.configure_server do |config|
  config.redis = { namespace: 'quill_sidekiq' }

  cron_file = 'config/sidekiq-cron.yml'
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(cron_file) if File.exist?(cron_file) && Sidekiq.server?
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: 'quill_sidekiq' }
end

Sidekiq::Throttled.setup!
