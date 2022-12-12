# frozen_string_literal: true

class MixinMessages::ProcessJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(message_id)
    MixinMessage.find_by(message_id: message_id)&.process!
  end
end
