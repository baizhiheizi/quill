# frozen_string_literal: true

require "test_helper"

class ArticlePublishedNotifierTest < ActiveSupport::TestCase
  setup do
    @subscriber = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_paid)
    ensure_notification_setting!(@subscriber)
  end

  test "message joins the author name, the published translation, and the article title" do
    deliver_notifier!(ArticlePublishedNotifier, record: @article, article: @article, recipient: @subscriber)

    notification = notification_for(@subscriber)

    assert_includes notification.message, @author.name.truncate(10)
    assert_includes notification.message,
                    I18n.t("notifiers.article_published_notifier.notification.published")
    assert_includes notification.message, @article.title
  end

  test "url anchors to the published article on the author's article page" do
    deliver_notifier!(ArticlePublishedNotifier, record: @article, article: @article, recipient: @subscriber)

    assert_includes notification_for(@subscriber).url, @article.uuid
  end
end
