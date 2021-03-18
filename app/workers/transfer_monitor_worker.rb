# frozen_string_literal: true

class TransferMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = Transfer.unprocessed.where(created_at: ...(Time.current - 12.hours)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed transfers delay longer than 12 hour"
    )
  end
end
