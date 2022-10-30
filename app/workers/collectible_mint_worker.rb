# frozen_string_literal: true

class CollectibleMintWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Collectible.find_by(id: id)&.do_mint!
  end
end
