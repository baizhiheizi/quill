# frozen_string_literal: true

class BatchProcessTransferWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: true

  def perform
    Transfer.unprocessed.map(&:process_async)
  end
end
