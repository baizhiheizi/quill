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
    failed_count = 0

    snapshots.find_each do |snapshot|
      snapshot.process!
    rescue StandardError => e
      # Per-row isolation mirrors `Transfers::MonitorJob`: one poisoned
      # snapshot (e.g. `Payment.find_or_create_by!` raising) must not abort
      # the sweep before the admin delay-alert below fires — the alert is
      # the job's entire purpose.
      Rails.logger.error "MixinNetworkSnapshot ##{snapshot.id} failed to process in MonitorJob: #{e.class}: #{e.message}"
      # The log line alone leaves the failure invisible to error tracking, and
      # `ActiveRecord::RecordInvalid` is not retryable (see
      # `DailyStatistics::GenerateJob`), so this sweep is the row's only
      # recovery path — report it the way other per-item job rescues do.
      Rails.error.report(e, handled: true, severity: :warning,
                         context: { job: self.class.name, snapshot_id: snapshot.id })
      failed_count += 1
    end

    AdminNotificationService.new.text(
      "There are #{count} unprocessed snapshots delayed longer than 1 minute#{failure_note(failed_count)}"
    )
  end

  private

  # Tell "recovered" apart from "still broken": the delayed count alone reads
  # the same whether this sweep processed every row or some rows are still
  # stuck. The suffix only shows up when a row actually failed, so the healthy
  # message stays unchanged.
  def failure_note(failed_count)
    return "" if failed_count.zero?

    " (#{failed_count} failed to process)"
  end
end
