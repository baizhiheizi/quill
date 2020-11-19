# frozen_string_literal: true

class BatchProcessMixinNetworkSnapshotWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: true

  def perform
    MixinNetworkSnapshot.unprocessed.where(created_at: ...(Time.current - 5.minutes)).map(&:process_async)
  end
end
