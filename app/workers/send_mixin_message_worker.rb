# frozen_string_literal: true

class SendMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(message)
    r = MixinBot.api.send_message message
    raise r['error'].inspect if r['error'].present?
  end
end
