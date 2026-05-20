# frozen_string_literal: true

require "test_helper"

class DeliveryMethods::MixinBotTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @buyer = users(:reader_one)
    @article = articles(:published_paid)
    ensure_notification_setting!(@author)
    @order = create_buy_order!(article: @article, buyer: @buyer)
  end

  test "perform enqueues mixin message job with quill bot by default" do
    deliver_notifier!(ArticleBoughtNotifier, record: @order, order: @order, recipient: @author)
    perform_enqueued_jobs only: Noticed::EventJob

    notification = notification_for(@author)

    with_mixin_bot_delivery_stub do
      assert_enqueued_jobs 1, only: MixinMessages::SendJob do
        DeliveryMethods::MixinBot.perform_now(:mixin_bot, notification)
      end

      job = enqueued_jobs.find { |entry| entry[:job] == MixinMessages::SendJob }
      assert_equal "QuillBot", job[:args].last
    end
  end
end
