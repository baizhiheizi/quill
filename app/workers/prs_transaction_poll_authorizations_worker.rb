# frozen_string_literal: true

class PrsTransactionPollAuthorizationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    PrsTransaction.poll_authorizations
  end
end
