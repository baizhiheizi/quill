# frozen_string_literal: true

class ArweaveTransactions::BatchAcceptJob < ApplicationJob
  retry_on StandardError, attempts: 1

  def perform
    ArweaveTransaction.pending.each.map(&:accept!)
  end
end
