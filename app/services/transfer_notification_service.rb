# frozen_string_literal: true

class TransferNotificationService
  def call(recipient_id:, asset_id:, amount:, trace_id:)
    token = Payment::SUPPORTED_TOKENS.find(&->(_token) { _token[:asset_id] == asset_id })
    return if token.blank?

    message = PrsdiggBot.api.app_card(
      conversation_id: PrsdiggBot.api.unique_conversation_id(recipient_id),
      data: {
        icon_url: token[:icon_url],
        title: amount.to_f.round(8).to_s,
        description: token[:symbol],
        action: "mixin://snapshots?trace=#{trace_id}"
      }
    )

    SendMixinMessageWorker.perform_async message
  end
end
