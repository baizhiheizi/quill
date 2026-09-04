# frozen_string_literal: true

require "test_helper"

class CollectionListedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @subscriber = users(:reader_one)
    ensure_notification_setting!(@subscriber)
    @collection = create_collection!(author: @author, name: "Featured Bundle")
  end

  test "message separates the author name, translation, and collection name with colons and spaces" do
    deliver_notifier!(CollectionListedNotifier, record: @collection, collection: @collection, recipient: @subscriber)

    expected = [ @author.name.truncate(10),
                 I18n.t("notifiers.collection_listed_notifier.notification.listed"),
                 ":",
                 @collection.name ].join(" ")

    assert_equal expected, notification_for(@subscriber).message
  end

  test "description joins the truncated author name and the listed translation" do
    deliver_notifier!(CollectionListedNotifier, record: @collection, collection: @collection, recipient: @subscriber)

    expected = [ @author.name.truncate(10),
                 I18n.t("notifiers.collection_listed_notifier.notification.listed") ].join(" ")

    assert_equal expected, notification_for(@subscriber).data[:description]
  end

  test "icon_url is the author avatar" do
    deliver_notifier!(CollectionListedNotifier, record: @collection, collection: @collection, recipient: @subscriber)

    assert_equal @author.avatar_url, notification_for(@subscriber).data[:icon_url]
  end

  test "url anchors to the listed collection on the collection page" do
    deliver_notifier!(CollectionListedNotifier, record: @collection, collection: @collection, recipient: @subscriber)

    assert_includes notification_for(@subscriber).url, @collection.uuid
  end

  test "message truncates author names longer than 10 characters" do
    @author.update!(name: "x" * 20)
    collection = create_collection!(author: @author, name: "Featured")

    deliver_notifier!(CollectionListedNotifier, record: collection, collection: collection, recipient: @subscriber)

    notification = notification_for(@subscriber)
    truncated_name = @author.name.truncate(10)

    # String#truncate(10) on a 20-char string returns "xxxxxxx..." (10 chars total).
    assert_equal [ truncated_name,
                   I18n.t("notifiers.collection_listed_notifier.notification.listed"),
                   ":",
                   "Featured" ].join(" "),
                 notification.message
    assert_equal 10, truncated_name.length
  end

  test "data title truncates collection names longer than 36 characters" do
    deliver_collection_named("x" * 60)

    assert_equal ("x" * 60).truncate(36), notification_for(@subscriber).data[:title]
  end

  test "data description truncates content longer than 72 characters" do
    deliver_collection_named("y" * 80)

    assert notification_for(@subscriber).data[:description].length <= 72
  end

  private

  def deliver_collection_named(name)
    collection = create_collection!(author: @author, name: name)

    deliver_notifier!(CollectionListedNotifier, record: collection, collection: collection, recipient: @subscriber)
  end
end
