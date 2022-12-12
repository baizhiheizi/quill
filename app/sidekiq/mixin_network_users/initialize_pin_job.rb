# frozen_string_literal: true

class MixinNetworkUsers::InitializePinJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(id)
    MixinNetworkUser.find_by(id: id)&.initialize_pin!
  end
end
