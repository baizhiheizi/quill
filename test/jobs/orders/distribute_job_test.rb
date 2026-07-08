# frozen_string_literal: true

require "test_helper"

class Orders::DistributeJobTest < JobTestCase
  # DistributeJob re-fetches the order via `Order.find_by`, so per-instance
  # stubs don't survive. Stub the guard on the class for the test's duration
  # (the same pattern used in transfer_test.rb / user_authorization_test.rb).
  ORIGINAL_ALL_TRANSFERS_GENERATED = Order.instance_method(:all_transfers_generated?)

  def with_all_transfers_generated!
    Order.define_method(:all_transfers_generated?) { true }
    yield
  ensure
    Order.define_method(:all_transfers_generated?, ORIGINAL_ALL_TRANSFERS_GENERATED)
  end

  test "perform calls distribute! on order" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)

      with_all_transfers_generated! do
        Orders::DistributeJob.perform_now(order.trace_id)
      end

      assert order.transfers.exists?
    end
  end

  test "order create enqueues distribute job" do
    with_quill_bot_stub do
      assert_enqueued_with(job: Orders::DistributeJob) do
        create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      end
    end
  end
end
