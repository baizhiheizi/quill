# frozen_string_literal: true

require "test_helper"

class ApplicationNotifierTest < ActiveSupport::TestCase
  test "kinds that cannot reach the inbox are declared, not hard-coded" do
    assert_not NotificationKind.fetch(:user_connected).web?
    assert_not NotificationKind.fetch(:user_safe_registration).web?
  end

  test "an unknown kind names the declaration it is missing" do
    error = assert_raises(NotificationKind::NotFoundError) { NotificationKind.fetch(:nonexistent) }

    assert_match(/nonexistent/, error.message)
  end

  test "action cable messages are formatted in the recipient's locale" do
    subscriber = users(:reader_one)
    subscriber.update! locale: "ja"
    ensure_notification_setting!(subscriber)

    deliver_notifier!(
      ArticlePublishedNotifier,
      record: articles(:published_paid),
      article: articles(:published_paid),
      recipient: subscriber
    )

    I18n.with_locale :ja do
      expected = [
        users(:author).name.truncate(10),
        I18n.t("notifiers.article_published_notifier.notification.published"),
        ":",
        articles(:published_paid).title
      ].join(" ")

      assert_equal expected, notification_for(subscriber).format_for_action_cable
    end
  end
end
