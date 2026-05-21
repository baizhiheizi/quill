# frozen_string_literal: true

class ArweaveTransactions::BatchAcceptJob < ApplicationJob
  queue_as :low
  retry_on StandardError, attempts: 1

  def perform
    ArweaveTransaction.pending.each.map(&:accept!)
  end
end
