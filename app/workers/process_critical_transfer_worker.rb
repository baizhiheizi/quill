# frozen_string_literal: true

class ProcessCriticalTransferWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  sidekiq_retry_in do |count, exception|
    case exception
    when MixinBot::InsufficientPoolError, MixinBot::PinError
      1 if count < 10
    end
  end

  def perform(trace_id)
    Transfer.find_by(trace_id: trace_id)&.process!
  end
end
