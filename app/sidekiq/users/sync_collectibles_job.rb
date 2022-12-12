# frozen_string_literal: true

class Users::SyncCollectiblesJob
  include Sidekiq::Job

  def perform(id)
    User.find_by(id: id)&.sync_collectibles!
  end
end
