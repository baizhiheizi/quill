# frozen_string_literal: true

require "test_helper"

class SubscribeUserActionCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @subscriber = users(:reader_one)
    @author = users(:author)
    ensure_notification_setting!(@subscriber)
  end

  test "deliver creates a noticed event and notification record" do
    action = build_subscribe_action!

    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          SubscribeUserActionCreatedNotifier,
          record: action,
          action: action,
          recipient: @author
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@author)

    assert_equal "SubscribeUserActionCreatedNotifier", event.type
    assert_equal action, event.record
    assert_equal action, notification.params[:action]
    assert notification.visible_in_web?
  end

  test "message joins the subscriber name and the subscribed translation" do
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    notification = notification_for(@author)

    assert_equal [ @subscriber.name.truncate(10),
                   I18n.t("notifiers.subscribe_user_action_created_notifier.notification.subscribed") ].join(" "),
                 notification.message
  end

  test "message truncates subscriber names longer than 10 characters" do
    @subscriber.update!(name: "x" * 20)
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    notification = notification_for(@author)
    truncated_name = @subscriber.name.truncate(10)

    # String#truncate(10) on a 20-char string returns "xxxxxxx..." (10 chars total).
    assert_equal [ truncated_name,
                   I18n.t("notifiers.subscribe_user_action_created_notifier.notification.subscribed") ].join(" "),
                 notification.message
    assert_equal 10, truncated_name.length
  end

  test "url anchors to the subscriber's profile page" do
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    notification = notification_for(@author)

    assert_includes notification.url, @subscriber.uid
  end

  test "data payload exposes the PLAIN_TEXT shape used for mixin bot delivery" do
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    notification = notification_for(@author)

    assert_equal notification.message, notification.data
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @author.messenger?

    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot is false when recipient is not a messenger" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "twitter")
    non_messenger_recipient = users(:reader_two)
    non_messenger_recipient.create_notification_setting! if non_messenger_recipient.notification_setting.blank?
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: non_messenger_recipient
    )

    notification = notification_for(non_messenger_recipient)
    assert_not notification.may_notify_via_mixin_bot?
  end

  test "deliver does not send a mixin bot message when recipient is not a messenger" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "twitter")
    non_messenger_recipient = users(:reader_two)
    non_messenger_recipient.create_notification_setting! if non_messenger_recipient.notification_setting.blank?
    action = build_subscribe_action!

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: non_messenger_recipient
    )

    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  private

  # Build a persisted Action without firing the after_create :notify_target
  # callback (which would deliver the notifier and double every event/job
  # count in these tests).
  def build_subscribe_action!
    Action.skip_callback :create, :after, :notify_target
    begin
      Action.create!(
        action_type: "subscribe",
        user: @subscriber,
        target: @author,
        user_type: "User",
        target_type: "User"
      )
    ensure
      Action.set_callback :create, :after, :notify_target
    end
  end
end
