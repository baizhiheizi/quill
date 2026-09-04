# frozen_string_literal: true

require "test_helper"

class CollectionBoughtNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @subscriber = users(:reader_two)
    ensure_notification_setting!(@subscriber)
    @collection = create_collection!(author: @author, name: "Featured Bundle")
    @order = create_order!(item: @collection, buyer: @buyer)
  end

  test "message separates the buyer name, translation, and collection name with colons and spaces" do
    deliver_notifier!(CollectionBoughtNotifier, record: @order, order: @order, recipient: @subscriber)

    expected = [ @buyer.name.truncate(10),
                 I18n.t("notifiers.collection_bought_notifier.notification.bought"),
                 ":",
                 @collection.name ].join(" ")

    assert_equal expected, notification_for(@subscriber).message
  end

  test "description joins the truncated buyer name and the bought translation" do
    deliver_notifier!(CollectionBoughtNotifier, record: @order, order: @order, recipient: @subscriber)

    expected = [ @buyer.name.truncate(10),
                 I18n.t("notifiers.collection_bought_notifier.notification.bought") ].join(" ")

    assert_equal expected, notification_for(@subscriber).data[:description]
  end

  test "url anchors to the bought collection on the collection page" do
    deliver_notifier!(CollectionBoughtNotifier, record: @order, order: @order, recipient: @subscriber)

    assert_includes notification_for(@subscriber).url, @collection.uuid
  end

  test "data title truncates collection names longer than 36 characters" do
    deliver_collection_named("x" * 60)

    assert_equal ("x" * 60).truncate(36), notification_for(@subscriber).data[:title]
  end

  test "data description truncates content longer than 72 characters" do
    deliver_collection_named("y" * 80)

    assert notification_for(@subscriber).data[:description].length <= 72
  end

  test "a subscriber who blocked the buyer keeps the row out of the inbox" do
    @subscriber.create_action(:block, target: @buyer)

    deliver_notifier!(CollectionBoughtNotifier, record: @order, order: @order, recipient: @subscriber)

    notification = notification_for(@subscriber)
    assert_not notification.web_visible?
    assert_not notification.may_notify_via_mixin_bot?
  end

  private

  def deliver_collection_named(name)
    collection = create_collection!(author: @author, name: name)
    order = create_order!(item: collection, buyer: @buyer)

    deliver_notifier!(CollectionBoughtNotifier, record: order, order: order, recipient: @subscriber)
  end
end
