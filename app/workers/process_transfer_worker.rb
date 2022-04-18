# frozen_string_literal: true

class ProcessTransferWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: true

  sidekiq_retry_in do |count, exception|
    case exception
    when MixinBot::InsufficientPoolError, MixinBot::PinError
      SecureRandom.random_number(60) if count < 10
    end
  end

  def perform(trace_id)
    Transfer.find_by(trace_id: trace_id)&.process!
  end
end
