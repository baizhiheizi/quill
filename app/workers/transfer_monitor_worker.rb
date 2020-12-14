# frozen_string_literal: true

class TransferMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = Transfer.unprocessed.where(created_at: ...(Time.current - 1.hour)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed transfers delay longer than 1 hour"
    )
  end
end
