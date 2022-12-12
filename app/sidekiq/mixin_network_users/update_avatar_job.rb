# frozen_string_literal: true

class MixinNetworkUsers::UpdateAvatarJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(id)
    MixinNetworkUser.find_by(id: id)&.update_avatar
  end
end
