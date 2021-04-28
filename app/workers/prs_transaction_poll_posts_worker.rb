# frozen_string_literal: true

class PrsTransactionPollAuthorizationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    PrsTransaction.poll_posts
  end
end
