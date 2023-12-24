# frozen_string_literal: true

class MixinNetworkUsers::InitializePinJob < ApplicationJob
  def perform(id)
    MixinNetworkUser.find_by(id: id)&.initialize_pin!
  end
end
