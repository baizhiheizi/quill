# frozen_string_literal: true

class MixinNetworkSnapshots::ProcessJob < ApplicationJob
  queue_as :critical

  def perform(id)
    MixinNetworkSnapshot.find_by(id:)&.process!
  end
end
