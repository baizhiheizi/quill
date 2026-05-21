# frozen_string_literal: true

class Transfers::MonitorJob < ApplicationJob
  queue_as :low

  def perform(*_args)
    transfers = Transfer.unprocessed.where(created_at: ...(12.hours.ago))
    return if transfers.none?

    count = transfers.count
    transfers.find_each(&:process!)
    AdminNotificationService.new.text(
      "There are #{count} unprocessed transfers delay longer than 12 hour"
    )
  end
end
