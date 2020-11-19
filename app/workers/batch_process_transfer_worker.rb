# frozen_string_literal: true

class BatchProcessTransferWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform
    Transfer.unprocessed.where(created_at: ...(Time.current - 5.minutes)).map(&:process_async)
  end
end
