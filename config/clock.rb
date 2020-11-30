# frozen_string_literal: true

# Initialize sidekiq
require 'sidekiq'
require_relative './initializers/sidekiq'
def sidekiq_perform_async(worker_name)
  ::Sidekiq::Client.push('class' => worker_name, 'args' => [])
end

# Initialize Clockwork
require 'clockwork'
module Clockwork
  configure do |config|
    config[:tz] = 'Asia/Hong_Kong'
  end
end
