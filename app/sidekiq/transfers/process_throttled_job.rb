# frozen_string_literal: true

class Transfers::ProcessThrottledJob
  include Sidekiq::Job
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low, retry: true

  sidekiq_throttle(
    concurrency: { limit: 5, key_suffix: ->(_, wallet_id) { wallet_id } }
  )

  sidekiq_retry_in do |count, exception|
    case exception
    when MixinBot::InsufficientPoolError, MixinBot::PinError
      SecureRandom.random_number(600) if count < 10
    end
  end

  def perform(trace_id, wallet_id)
    Transfer.find_by(trace_id: trace_id, wallet_id: wallet_id)&.process!
  end
end
