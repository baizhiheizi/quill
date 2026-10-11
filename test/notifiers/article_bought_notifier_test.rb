# frozen_string_literal: true

require "test_helper"

class ArticleBoughtNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@author)
    @order = create_buy_order!(article: @article, buyer: @buyer)
  end

  test "message names the buyer and the bought article" do
    deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)

    notification = notification_for(@author)

    assert_includes notification.message, @buyer.name
    assert_includes notification.message, @article.title
  end

  test "a recipient who blocked the buyer keeps the row out of the inbox" do
    @author.create_action(:block, target: @buyer)

    deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)

    notification = notification_for(@author)
    assert_not notification.web_visible?
    assert_not notification.may_notify_via_mixin_bot?
  end
end
