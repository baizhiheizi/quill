# frozen_string_literal: true

class SendMixinMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(message, bot = 'QuillBot')
    if bot == 'RevenueBot'
      RevenueBot.api.send_message message
    else
      QuillBot.api.send_message message
    end
  rescue MixinBot::ForbiddenError, MixinBot::UnauthorizedError => e
    Rails.logger.error e.inspect
    raise e if Rails.env.development?
  end
end
