# frozen_string_literal: true

require "test_helper"

class TaggingCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @recipient = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_paid)
    @tagging = taggings(:published_paid_web3)
    ensure_notification_setting!(@recipient)
  end

  test "deliver creates a visible web notification with tag name and article title" do
    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    assert_includes notification.message, "##{@tagging.tag.name}"
    assert_includes notification.message,
                    I18n.t("notifiers.tagging_created_notifier.notification.has_new_article")
    assert_includes notification.message, @article.title
    assert notification.visible_in_web?
  end

  test "url anchors to the tagged article on the author's article page" do
    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    assert_includes notification.url, @article.uuid
  end

  test "data payload exposes the APP_CARD shape for mixin bot delivery" do
    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    payload = notification.data
    assert_equal ApplicationNotifier::QUILL_ICON_URL, payload[:icon_url]
    assert_equal @article.title.truncate(36), payload[:title]
    assert_includes payload[:description], "##{@tagging.tag.name}"
    assert_includes payload[:action], @article.uuid
  end

  test "visible_in_web is false when recipient blocked the article author" do
    @recipient.create_action(:block, target: @author)

    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    assert_not notification_for(@recipient).visible_in_web?
  end

  test "visible_in_web is false when recipient disables web notifications" do
    @recipient.notification_setting.update!(tagging_created_web: false)

    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    assert_not notification_for(@recipient).visible_in_web?
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @recipient.messenger?

    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "deliver does not enqueue mixin bot delivery when recipient disabled mixin bot" do
    @recipient.notification_setting.update!(tagging_created_mixin_bot: false)

    deliver_notifier!(
      TaggingCreatedNotifier,
      record: @tagging,
      tagging: @tagging,
      recipient: @recipient
    )

    perform_enqueued_jobs only: Noticed::EventJob

    assert_no_enqueued_jobs only: DeliveryMethods::MixinBot
  end
end
