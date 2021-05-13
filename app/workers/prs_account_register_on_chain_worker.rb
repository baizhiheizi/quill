# frozen_string_literal: true

class PrsAccountRegisterOnChainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pressone, retry: true

  def perform(id)
    PrsAccount.find(id).register_on_chain!
  end
end
