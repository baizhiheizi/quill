# frozen_string_literal: true

class ProcessMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(message_id)
    MixinMessage.find_by(message_id: message_id)&.process!
  end
end
