# frozen_string_literal: true

class MixinMessages::ProcessJob < ApplicationJob
  def perform(message_id)
    MixinMessage.find_by(message_id:)&.process!
  end
end
