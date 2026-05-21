# frozen_string_literal: true

class MixinNetworkUsers::UpdateAvatarJob < ApplicationJob
  queue_as :default
  def perform(id)
    MixinNetworkUser.find_by(id:)&.update_avatar
  end
end
