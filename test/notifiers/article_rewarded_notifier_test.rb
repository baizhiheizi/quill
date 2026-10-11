# frozen_string_literal: true

require "test_helper"

class ArticleRewardedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@author)
    @order = create_buy_order!(article: @article, buyer: @buyer)
  end

  test "message names the buyer, the rewarded translation, and the article" do
    deliver_notifier!(ArticleRewardedNotifier, record: @order, order: @order, recipient: @author)

    notification = notification_for(@author)

    assert_includes notification.message, @buyer.name.truncate(10)
    assert_includes notification.message,
                    I18n.t("notifiers.article_rewarded_notifier.notification.rewarded")
    assert_includes notification.message, @article.title
  end

  test "url anchors to the rewarded article on the author's article page" do
    deliver_notifier!(ArticleRewardedNotifier, record: @order, order: @order, recipient: @author)

    assert_includes notification_for(@author).url, @article.uuid
  end

  test "a recipient who blocked the buyer keeps the row out of the inbox" do
    @author.create_action(:block, target: @buyer)

    deliver_notifier!(ArticleRewardedNotifier, record: @order, order: @order, recipient: @author)

    notification = notification_for(@author)
    assert_not notification.web_visible?
    assert_not notification.may_notify_via_mixin_bot?
  end
end
