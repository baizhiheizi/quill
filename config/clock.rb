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

  every 1.minute, 'batch_process_transfer_worker.rb' do
    sidekiq_perform_async('BatchProcessTransferWorker')
  end

  every 1.minute, 'batch_process_mixin_message_worker.rb' do
    sidekiq_perform_async('BatchProcessMixinMessageWorker')
  end

  every 1.minute, 'batch_process_mixin_network_snapshot_worker.rb' do
    sidekiq_perform_async('BatchProcessMixinNetworkSnapshotWorker')
  end
end
