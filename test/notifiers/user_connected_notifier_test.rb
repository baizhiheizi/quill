# frozen_string_literal: true

require "test_helper"

class UserConnectedNotifierTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
  end

  test "deliver creates a notification record but hides it from the web UI" do
    assert_difference -> { Noticed::Notification.count }, 1 do
      deliver_notifier!(UserConnectedNotifier, record: @user, user: @user, recipient: @user)
    end

    notification = notification_for(@user)

    assert_equal I18n.t("notifiers.user_connected_notifier.notification.message"), notification.message
    assert_not notification.visible_in_web?
    assert_not_includes @user.notifications.for_web, notification
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    deliver_notifier!(UserConnectedNotifier, record: @user, user: @user, recipient: @user)

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end
end
