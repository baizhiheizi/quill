# frozen_string_literal: true

class Currencies::SyncJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: false

  def perform
    Currency.swappable.map(&:sync!)
  end
end
