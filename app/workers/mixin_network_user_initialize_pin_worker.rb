# frozen_string_literal: true

class MixinNetworkUserInitializePinWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    MixinNetworkUser.find_by(id: id)&.initialize_pin!
  end
end
