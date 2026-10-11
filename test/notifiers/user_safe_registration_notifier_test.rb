# frozen_string_literal: true

require "test_helper"

class UserSafeRegistrationNotifierTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
  end

  test "deliver creates a notification record but no web-inbox row" do
    assert_difference -> { Noticed::Notification.count }, 1 do
      deliver_notifier!(UserSafeRegistrationNotifier, record: @user, user: @user, recipient: @user)
    end

    notification = notification_for(@user)

    assert_equal I18n.t("notifiers.user_safe_registration_notifier.notification.message"), notification.message
    assert_not notification.web_visible?
    assert_not_includes @user.notifications.for_web, notification
  end

  test "url is nil because the notification targets an in-app action on Mixin Messenger" do
    deliver_notifier!(UserSafeRegistrationNotifier, record: @user, user: @user, recipient: @user)

    assert_nil notification_for(@user).url
  end
end
