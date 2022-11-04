# frozen_string_literal: true

class SyncCurrencyPriceWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform
    Currency.swappable.map(&:sync!)
  end
end
