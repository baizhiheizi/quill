# frozen_string_literal: true

class MixinNetworkSnapshotMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    snapshots = MixinNetworkSnapshot.unprocessed.where(created_at: ...(1.minute.ago))
    return unless snapshots.count.positive?

    snapshots.map(&:process!)
    AdminNotificationService.new.text(
      "There are #{snapshots.count} unprocessed snapshots delay longer than 1 minutes"
    )
  end
end
