# frozen_string_literal: true

class BatchProcessMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: true

  def perform
    MixinMessage.unprocessed.where(created_at: ...(Time.current - 5.minutes)).map(&:process_async)
  end
end
