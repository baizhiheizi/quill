# frozen_string_literal: true

class TransferMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = Transfer.unprocessed.where(created_at: ...(12.hours.ago)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed transfers delay longer than 12 hour"
    )
  end
end
