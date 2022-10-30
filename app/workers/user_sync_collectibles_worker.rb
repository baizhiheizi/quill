# frozen_string_literal: true

class UserSyncCollectiblesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    User.find_by(id: id)&.sync_collectibles!
  end
end
