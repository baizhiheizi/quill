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

  test "deliver creates noticed event and notification records" do
    assert_difference -> { Noticed::Event.count }, 1 do
      assert_difference -> { Noticed::Notification.count }, 1 do
        deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)
      end
    end

    event = Noticed::Event.last
    notification = notification_for(@author)

    assert_equal "ArticleBoughtNotifier", event.type
    assert_equal @order, event.record
    assert_equal @order, notification.params[:order]
    assert_includes notification.message, @buyer.name
    assert_includes notification.message, @article.title
    assert notification.visible_in_web?
  end

  test "visible_in_web is false when author disables web notifications" do
    @author.notification_setting.update!(article_bought_web: false)

    deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)

    assert_not notification_for(@author).visible_in_web?
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end
end
