# frozen_string_literal: true

class ProcessMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  def perform(message_id)
    MixinMessage.find_by(message_id: message_id)&.process!
  end
end
