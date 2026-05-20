# frozen_string_literal: true

module NotifierHelpers
  def ensure_notification_setting!(user)
    user.create_notification_setting! if user.notification_setting.blank?
    user.notification_setting
  end

  def with_mixin_bot_delivery_stub
    with_quill_bot_stub do
      api = QuillBot.api
      api.define_singleton_method(:base_message_params) { |params| params.deep_stringify_keys }
      yield
    end
  end

  def deliver_notifier!(notifier_class, record:, recipient:, **params)
    notifier_class.with(record: record, **params).deliver(recipient)
  end

  def notification_for(recipient)
    recipient.notifications.order(:id).last
  end
end
