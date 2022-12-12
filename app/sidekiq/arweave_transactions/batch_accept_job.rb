# frozen_string_literal: true

class ArweaveTransactions::BatchAcceptJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: false

  def perform
    ArweaveTransaction.pending.each.map(&:accept!)
  end
end
