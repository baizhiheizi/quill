# frozen_string_literal: true

class MixinNetworkSnapshots::MonitorJob < ApplicationJob
  queue_as :low

  def perform
    snapshots = MixinNetworkSnapshot.unprocessed.where(created_at: ...(1.minute.ago))
    return if snapshots.none?

    # Capture the delayed count before processing: the relation re-queries
    # `processed_at IS NULL` on every `count`, so reading it again after the
    # loop would report however many rows are still stuck (0 when this run
    # processed them all) instead of how many were delayed.
    count = snapshots.count
    snapshots.find_each do |snapshot|
      snapshot.process!
    rescue StandardError => e
      # Per-row isolation mirrors `Transfers::MonitorJob`: one poisoned
      # snapshot (e.g. `Payment.find_or_create_by!` raising) must not abort
      # the sweep before the admin delay-alert below fires — the alert is
      # the job's entire purpose.
      Rails.logger.error "MixinNetworkSnapshot ##{snapshot.id} failed to process in MonitorJob: #{e.class}: #{e.message}"
    end

    AdminNotificationService.new.text(
      "There are #{count} unprocessed snapshots delayed longer than 1 minute"
    )
  end
end
