# frozen_string_literal: true

class BatchArweaveTxAcceptWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    ArweaveTransaction.pending.each.map(&:accept!)
  end
end
