# frozen_string_literal: true

class UserCreateBotContactConversationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    User.find(id).create_bot_contact_conversation
  end
end
