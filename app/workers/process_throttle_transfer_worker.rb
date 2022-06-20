# frozen_string_literal: true

class ProcessThrottleTransferWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low, retry: true

  sidekiq_throttle(
    concurrency: { limit: 5, key_suffix: ->(_, wallet_id) { wallet_id } }
  )

  sidekiq_retry_in do |count, exception|
    case exception
    when MixinBot::InsufficientPoolError, MixinBot::PinError
      SecureRandom.random_number(300) if count < 10
    end
  end

  def perform(trace_id, _wallet_id = nil)
    Transfer.find_by(trace_id: trace_id)&.process!
  end
end
