# frozen_string_literal: true

class SendMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(message)
    r = MixinBot.api.send_message message
    return if r['error'].blank?
    return if r['error']['code'] == 403

    raise r['error'].inspect
  end
end
