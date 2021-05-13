# frozen_string_literal: true

class PrsAccountDenyOnChainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pressone, retry: true

  def perform(id)
    PrsAccount.find(id).deny_on_chain!
  end
end
