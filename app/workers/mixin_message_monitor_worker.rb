# frozen_string_literal: true

class MixinMessageMonitorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    count = MixinMessage.unprocessed.where(created_at: ...(1.minute.ago)).count
    return unless count.positive?

    AdminNotificationService.new.text(
      "There are #{count} unprocessed messages delay longer than 1 minute"
    )
  end
end
