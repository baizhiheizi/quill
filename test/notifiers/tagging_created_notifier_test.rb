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

  test "message joins the tag, the has_new_article translation, and the article title" do
    deliver_notifier!(TaggingCreatedNotifier, record: @tagging, tagging: @tagging, recipient: @recipient)

    notification = notification_for(@recipient)

    assert_includes notification.message, "##{@tagging.tag.name}"
    assert_includes notification.message,
                    I18n.t("notifiers.tagging_created_notifier.notification.has_new_article")
    assert_includes notification.message, @article.title
  end

  test "icon_url is the Quill icon because a tag has no avatar" do
    deliver_notifier!(TaggingCreatedNotifier, record: @tagging, tagging: @tagging, recipient: @recipient)

    assert_equal ApplicationNotifier::QUILL_ICON_URL, notification_for(@recipient).data[:icon_url]
  end

  test "url anchors to the tagged article on the author's article page" do
    deliver_notifier!(TaggingCreatedNotifier, record: @tagging, tagging: @tagging, recipient: @recipient)

    assert_includes notification_for(@recipient).url, @article.uuid
  end

  test "a recipient who blocked the author keeps the row out of the inbox" do
    @recipient.create_action(:block, target: @author)

    deliver_notifier!(TaggingCreatedNotifier, record: @tagging, tagging: @tagging, recipient: @recipient)

    notification = notification_for(@recipient)
    assert_not notification.web_visible?
    assert_not notification.may_notify_via_mixin_bot?
  end
end
