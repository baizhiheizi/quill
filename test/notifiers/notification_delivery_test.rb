# frozen_string_literal: true

require "test_helper"

# One suite over every declared notification kind, covering the delivery
# behaviour that used to be copied into each notifier test. Per-notifier tests
# keep only what is genuinely different about a notifier.
class NotificationDeliveryTest < ActiveSupport::TestCase
  KINDS = NotificationKind.all.map(&:name)

  setup do
    @recipient = users(:author)
    ensure_notification_setting!(@recipient)
  end

  KINDS.each do |kind|
    test "#{kind}: delivers a row that is visible exactly when the kind is" do
      declared = NotificationKind.fetch(kind)

      deliver!(kind)

      notification = notification_for(@recipient)
      assert_equal declared.notification_type, notification.type
      assert_equal declared.web?, notification.web_visible?
      assert_equal declared.web?, @recipient.notifications.reload.for_web.include?(notification)
    end

    test "#{kind}: guards mixin delivery on the recipient being a messenger" do
      non_messenger = non_messenger_recipient

      deliver!(kind, recipient: non_messenger)

      assert_not notification_for(non_messenger).may_notify_via_mixin_bot?
    end

    test "#{kind}: enqueues mixin bot delivery for a messenger recipient" do
      assert_predicate @recipient, :messenger?

      deliver!(kind)

      assert_enqueued_jobs 1, only: Noticed::EventJob

      perform_enqueued_jobs only: Noticed::EventJob

      assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
    end
  end

  NotificationKind.all.select(&:card?).reject { |kind| kind.name == :transfer_processed }.each do |kind|
    test "#{kind.name}: renders the four APP_CARD keys" do
      deliver!(kind.name)

      notification = notification_for(@recipient)
      payload = notification.data

      assert_equal %i[icon_url title description action], payload.keys
      assert_equal notification.icon_url, payload[:icon_url]
      assert_equal notification.title.truncate(36), payload[:title]
      assert_equal notification.description.truncate(72), payload[:description]
      assert_equal notification.url, payload[:action]
    end
  end

  test "transfer_processed: renders the card with the snapshot action and shareable off" do
    deliver!(:transfer_processed)

    payload = notification_for(@recipient).data

    assert_equal %i[icon_url title description action shareable], payload.keys
    assert_equal false, payload[:shareable]
    assert_match %r{\Amixin://snapshots}, payload[:action]
  end

  NotificationKind.all.reject(&:card?).each do |kind|
    test "#{kind.name}: sends the message as its mixin payload" do
      deliver!(kind.name)

      notification = notification_for(@recipient)

      assert_equal notification.message, notification.data
    end
  end

  NotificationKind.with_settings.each do |kind|
    test "#{kind.name}: muting web stops the kind producing visible rows" do
      @recipient.notification_setting.update! kind.setting_key(:web) => false

      deliver!(kind.name)

      notification = notification_for(@recipient)
      assert_not notification.web_visible?
      assert_not_includes @recipient.notifications.reload.for_web, notification
    end

    test "#{kind.name}: muting mixin bot skips the message" do
      @recipient.notification_setting.update! kind.setting_key(:mixin_bot) => false

      deliver!(kind.name)

      assert notification_for(@recipient).web_visible?
      assert_not notification_for(@recipient).may_notify_via_mixin_bot?

      perform_enqueued_jobs only: Noticed::EventJob
      perform_enqueued_jobs only: DeliveryMethods::MixinBot

      assert_no_enqueued_jobs only: MixinMessages::SendJob
    end
  end

  private

  def deliver!(kind, recipient: @recipient)
    record, params = build_notification_delivery!(kind, recipient: recipient)

    deliver_notifier!(NotificationKind.fetch(kind).notifier.constantize, record: record, recipient: recipient, **params)
  end

  def non_messenger_recipient
    user_authorizations(:reader_two_auth).update! provider: "twitter"
    user = users(:reader_two)
    ensure_notification_setting!(user)
    user
  end
end
