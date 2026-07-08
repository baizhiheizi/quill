# frozen_string_literal: true

require "test_helper"

class Orders::BatchDistributeJobTest < JobTestCase
  test "perform calls distribute_async on paid orders" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      called = false
      order.define_singleton_method(:distribute_async) { called = true }

      paid_orders = Order.where(id: order.id)
      paid_orders.define_singleton_method(:find_in_batches) do |batch_size: 100, &_block|
        _block.call([ order ])
      end

      stub_class_method(Order, :paid, -> { paid_orders }) do
        Orders::BatchDistributeJob.perform_now
      end

      assert called
    end
  end

  test "perform isolates per-order enqueue failures and keeps processing" do
    with_quill_bot_stub do
      first = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      second = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_two), total: 1.0)

      second_called = false
      # The first order's enqueue raises; the second must still be dispatched.
      first.define_singleton_method(:distribute_async) { raise StandardError, "enqueue failed" }
      second.define_singleton_method(:distribute_async) { second_called = true }

      paid_orders = [ first, second ]
      paid_orders.define_singleton_method(:find_in_batches) do |batch_size: 100, &block|
        block.call(paid_orders)
      end

      stub_class_method(Order, :paid, -> { paid_orders }) do
        Orders::BatchDistributeJob.perform_now
      end

      assert second_called, "second order should be dispatched despite the first raising"
    end
  end
end
