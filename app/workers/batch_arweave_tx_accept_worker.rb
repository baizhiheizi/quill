# frozen_string_literal: true

class BatchArweaveTxAcceptWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    thrs = []
    ArweaveTransaction.where(state: :pending).each do |tx|
      thrs << Thread.new { tx.accept! }
    end

    thrs.join
  end
end
