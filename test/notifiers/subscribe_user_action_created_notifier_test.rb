# frozen_string_literal: true

require "test_helper"

class SubscribeUserActionCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @subscriber = users(:reader_one)
    @author = users(:author)
    ensure_notification_setting!(@author)
    @action = create_subscribe_action!(subscriber: @subscriber, target: @author)
  end

  test "message joins the subscriber name and the subscribed translation" do
    deliver_notifier!(SubscribeUserActionCreatedNotifier, record: @action, action: @action, recipient: @author)

    expected = [ @subscriber.name.truncate(10),
                 I18n.t("notifiers.subscribe_user_action_created_notifier.notification.subscribed") ].join(" ")

    assert_equal expected, notification_for(@author).message
  end

  test "message truncates subscriber names longer than 10 characters" do
    @subscriber.update! name: "x" * 20
    @action.destroy!
    action = create_subscribe_action!(subscriber: @subscriber, target: @author)

    deliver_notifier!(SubscribeUserActionCreatedNotifier, record: action, action: action, recipient: @author)

    truncated_name = @subscriber.name.truncate(10)

    # String#truncate(10) on a 20-char string returns "xxxxxxx..." (10 chars total).
    assert_equal [ truncated_name,
                   I18n.t("notifiers.subscribe_user_action_created_notifier.notification.subscribed") ].join(" "),
                 notification_for(@author).message
    assert_equal 10, truncated_name.length
  end

  test "url anchors to the subscriber's profile page" do
    deliver_notifier!(SubscribeUserActionCreatedNotifier, record: @action, action: @action, recipient: @author)

    assert_includes notification_for(@author).url, @subscriber.uid
  end
end
