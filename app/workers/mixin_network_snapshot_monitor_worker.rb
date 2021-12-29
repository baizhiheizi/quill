# frozen_string_literal: true

class MixinNetworkSnapshotMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = MixinNetworkSnapshot.unprocessed.where(created_at: ...(1.minute.ago)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed snapshots delay longer than 1 minutes"
    )
  end
end
