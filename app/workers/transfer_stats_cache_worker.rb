# frozen_string_literal: true

class TransferStatsCacheWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    Transfer.write_stats
  end
end
