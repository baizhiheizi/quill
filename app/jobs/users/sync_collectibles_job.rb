# frozen_string_literal: true

class Users::SyncCollectiblesJob < ApplicationJob
  def perform(id)
    User.find_by(id: id)&.sync_collectibles!
  end
end