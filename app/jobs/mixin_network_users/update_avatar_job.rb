# frozen_string_literal: true

class MixinNetworkUsers::UpdateAvatarJob < ApplicationJob
  def perform(id)
    MixinNetworkUser.find_by(id: id)&.update_avatar
  end
end
