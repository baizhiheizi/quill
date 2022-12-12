# frozen_string_literal: true

class Transfers::MonitorJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: false

  def perform(*_args)
    transfers = Transfer.unprocessed.where(created_at: ...(12.hours.ago)).count
    return if transfers.blank?

    transfers.map(&:process!)
    AdminNotificationService.new.text(
      "There are #{transfers.count} unprocessed transfers delay longer than 12 hour"
    )
  end
end
