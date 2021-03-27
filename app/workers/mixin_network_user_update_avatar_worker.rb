# frozen_string_literal: true

class MixinNetworkUserUpdateAvatarWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    MixinNetworkUser.find_by(id: id)&.update_avatar
  end
end
