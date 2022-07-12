# frozen_string_literal: true

class ProcessTransferWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: true

  sidekiq_retry_in do |count, exception|
    case exception
    when MixinBot::InsufficientPoolError, MixinBot::PinError
      SecureRandom.random_number(120) if count < 10
    end
  end

  def perform(trace_id)
    Transfer.find_by(trace_id: trace_id)&.process!
  end
end
