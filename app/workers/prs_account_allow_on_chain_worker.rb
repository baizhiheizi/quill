# frozen_string_literal: true

class PrsAccountAllowOnChainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pressone, retry: true

  def perform(id)
    PrsAccount.find(id).allow_on_chain!
  end
end
