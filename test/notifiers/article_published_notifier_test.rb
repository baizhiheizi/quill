# frozen_string_literal: true

require "test_helper"

class ArticlePublishedNotifierTest < ActiveSupport::TestCase
  setup do
    @subscriber = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_paid)
    ensure_notification_setting!(@subscriber)
  end

  test "deliver creates a visible web notification with author and title" do
    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_includes notification.message, @author.name.truncate(10)
    assert_includes notification.message,
                    I18n.t("notifiers.article_published_notifier.notification.published")
    assert_includes notification.message, @article.title
    assert notification.visible_in_web?
  end

  test "url anchors to the published article on the author's article page" do
    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_includes notification.url, @article.uuid
  end

  test "data payload exposes the APP_CARD shape for mixin bot delivery" do
    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    payload = notification.data
    assert_equal @author.avatar_url, payload[:icon_url]
    assert_equal @article.title.truncate(36), payload[:title]
    assert_includes payload[:description],
                    I18n.t("notifiers.article_published_notifier.notification.published")
    assert_includes payload[:action], @article.uuid
  end

  test "visible_in_web is false when subscriber disables web notifications" do
    @subscriber.notification_setting.update!(article_published_web: false)

    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    assert_not notification_for(@subscriber).visible_in_web?
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @subscriber.messenger?

    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "deliver does not send a mixin bot message when subscriber disabled mixin bot" do
    @subscriber.notification_setting.update!(article_published_mixin_bot: false)

    deliver_notifier!(
      ArticlePublishedNotifier,
      record: @article,
      article: @article,
      recipient: @subscriber
    )

    # Noticed's config.if gates delivery at perform time, not enqueue time, so
    # the MixinBot job is enqueued but no-ops when the setting is disabled.
    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end
end
