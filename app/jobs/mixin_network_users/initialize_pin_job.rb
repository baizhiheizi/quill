# frozen_string_literal: true

class MixinNetworkUsers::InitializePinJob < ApplicationJob
  queue_as :default
  def perform(id)
    MixinNetworkUser.find_by(id:)&.initialize_pin!
  end
end
