# frozen_string_literal: true

class Collectibles::TransferToOwnerJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Collectible.find_by(id: id)&.transfer_to_owner
  end
end
