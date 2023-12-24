# frozen_string_literal: true

class Currencies::SyncJob < ApplicationJob
  queue_as :low
  retry_on StandardError, attempts: 1

  def perform
    Currency.swappable.map(&:sync!)
  end
end
