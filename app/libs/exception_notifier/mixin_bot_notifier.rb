# frozen_string_literal: true

module ExceptionNotifier
  class MixinBotNotifier < ExceptionNotifier::BaseNotifier
    def initialize(options)
      super

      @recipient_id = options[:recipient_id]
      @conversation_id = options[:conversation_id] || PrsdiggBot.api.unique_uuid(@recipient_id)
    end

    def call(exception, _options = {})
      return if @conversation_id.blank?

      msg = PrsdiggBot.api.plain_text(
        conversation_id: @conversation_id,
        data: exception
      )

      SendMixinMessageWorker.perform_async msg
    end
  end
end
