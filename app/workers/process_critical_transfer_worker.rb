# frozen_string_literal: true

class ProcessCriticalTransferWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  def perform(trace_id)
    Transfer.find_by(trace_id: trace_id)&.process!
  end
end
