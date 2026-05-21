# frozen_string_literal: true

require "test_helper"

class Orders::BatchDistributeJobTest < JobTestCase
  test "perform calls distribute_async on paid orders" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      called = false
      order.define_singleton_method(:distribute_async) { called = true }

      paid_orders = Order.where(id: order.id)
      paid_orders.define_singleton_method(:find_each) do |&block|
        block.call(order)
      end

      stub_class_method(Order, :paid, -> { paid_orders }) do
        Orders::BatchDistributeJob.perform_now
      end

      assert called
    end
  end
end
