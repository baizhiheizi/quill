# frozen_string_literal: true

require "test_helper"

class CollectionListedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @subscriber = users(:reader_one)
    ensure_notification_setting!(@subscriber)
    @collection = create_collection!(author: @author, name: "Featured Bundle")
  end

  test "deliver creates noticed event and notification records" do
    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(
          CollectionListedNotifier,
          record: @collection,
          collection: @collection,
          recipient: @subscriber
        )
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@subscriber)

    assert_equal "CollectionListedNotifier", event.type
    assert_equal @collection, event.record
    assert_equal @collection, notification.params[:collection]
    assert notification.visible_in_web?
  end

  test "message joins the author name, the listed translation, and the collection name" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_equal [ @author.name.truncate(10),
                   I18n.t("notifiers.collection_listed_notifier.notification.listed"),
                   ":",
                   @collection.name ].join(" "),
                 notification.message
  end

  test "description joins the truncated author name and the listed translation" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert_equal [ @author.name.truncate(10),
                   I18n.t("notifiers.collection_listed_notifier.notification.listed") ].join(" "),
                 payload[:description]
  end

  test "url anchors to the listed collection on the collection page" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)

    assert_includes notification.url, @collection.uuid
  end

  test "data payload exposes the APP_CARD shape for mixin bot delivery" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert_equal @author.avatar_url, payload[:icon_url]
    assert_equal @collection.name.truncate(36), payload[:title]
    assert_includes payload[:description],
                    I18n.t("notifiers.collection_listed_notifier.notification.listed")
    assert_includes payload[:action], @collection.uuid
  end

  test "data title truncates collection names longer than 36 characters" do
    long_name = "x" * 60
    collection = create_collection!(author: @author, name: long_name)

    deliver_notifier!(
      CollectionListedNotifier,
      record: collection,
      collection: collection,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert_equal long_name.truncate(36), payload[:title]
  end

  test "data description truncates content longer than 72 characters" do
    long_name = "y" * 80
    collection = create_collection!(author: @author, name: long_name)

    deliver_notifier!(
      CollectionListedNotifier,
      record: collection,
      collection: collection,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert payload[:description].length <= 72
  end

  test "icon_url uses the author avatar" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    payload = notification_for(@subscriber).data

    assert_equal @author.avatar_url, payload[:icon_url]
  end

  test "message truncates author names longer than 10 characters" do
    @author.update!(name: "x" * 20)
    collection = create_collection!(author: @author, name: "Featured")

    deliver_notifier!(
      CollectionListedNotifier,
      record: collection,
      collection: collection,
      recipient: @subscriber
    )

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

  test "visible_in_web is false when subscriber disables web notifications" do
    @subscriber.notification_setting.update!(article_published_web: false)

    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    assert_not notification_for(@subscriber).visible_in_web?
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @subscriber.messenger?

    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end

  test "may_notify_via_mixin_bot is false when subscriber disabled mixin bot" do
    @subscriber.notification_setting.update!(article_published_mixin_bot: false)

    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    assert_not notification.may_notify_via_mixin_bot?
  end

  test "may_notify_via_mixin_bot is true for messenger recipients by default" do
    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: @subscriber
    )

    notification = notification_for(@subscriber)
    assert notification.may_notify_via_mixin_bot?
  end

  test "deliver does not enqueue a mixin bot message when recipient is not a messenger" do
    reader_two_auth = user_authorizations(:reader_two_auth)
    reader_two_auth.update!(provider: "fennec")
    fennec_recipient = users(:reader_two)
    fennec_recipient.create_notification_setting! if fennec_recipient.notification_setting.blank?

    deliver_notifier!(
      CollectionListedNotifier,
      record: @collection,
      collection: @collection,
      recipient: fennec_recipient
    )

    perform_enqueued_jobs only: Noticed::EventJob
    perform_enqueued_jobs only: DeliveryMethods::MixinBot

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  private

  def create_collection!(author:, name:)
    Collection.create!(
      uuid: SecureRandom.uuid,
      name: name,
      symbol: "FB",
      description: "Test collection",
      author: author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end
end
