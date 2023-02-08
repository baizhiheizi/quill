# frozen_string_literal: true

class Transfers::ProcessThrottledJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: true, lock: :while_executing, on_conflict: :reschedule, lock_args_method: :lock_args

  def self.lock_args(args)
    [args[1]]
  end

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
