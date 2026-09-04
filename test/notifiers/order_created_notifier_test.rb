# frozen_string_literal: true

require "test_helper"

class OrderCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@buyer)
  end

  test "message uses the bought translation and includes the article title for buy_article orders" do
    order = create_order!(item: @article, buyer: @buyer, order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.bought")
    assert_includes notification.message, @article.title
  end

  test "message uses the rewarded translation and includes the article title for reward_article orders" do
    order = create_order!(item: @article, buyer: @buyer, order_type: :reward_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.rewarded")
    assert_includes notification.message, @article.title
  end

  test "message includes the collection name for buy_collection orders" do
    collection = create_collection!(author: @author, name: "Featured Bundle")
    order = create_order!(item: collection, buyer: @buyer, order_type: :buy_collection)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    notification = notification_for(@buyer)

    assert_includes notification.message,
                    I18n.t("notifiers.order_created_notifier.notification.bought")
    assert_includes notification.message, "Featured Bundle"
  end

  test "url anchors to the article on a user_article_url for article items" do
    order = create_order!(item: @article, buyer: @buyer, order_type: :buy_article)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    assert_includes notification_for(@buyer).url, @article.uuid
  end

  test "url anchors to the collection for collection items" do
    collection = create_collection!(author: @author, name: "Featured Bundle")
    order = create_order!(item: collection, buyer: @buyer, order_type: :buy_collection)

    deliver_notifier!(OrderCreatedNotifier, record: order, order: order, recipient: @buyer)

    assert_includes notification_for(@buyer).url, collection.uuid
  end
end
