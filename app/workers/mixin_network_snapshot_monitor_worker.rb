# frozen_string_literal: true

class MixinNetworkSnapshotMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = MixinNetworkSnapshot.unprocessed.where(created_at: ...(Time.current - 1.minute)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed snapshots delay longer than 1 minutes"
    )
  end
end
