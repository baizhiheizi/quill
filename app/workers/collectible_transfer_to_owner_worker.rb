# frozen_string_literal: true

class CollectibleTransferToOwnerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Collectible.find_by(id: id)&.transfer_to_owner
  end
end
