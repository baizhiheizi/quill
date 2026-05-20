# frozen_string_literal: true

require "test_helper"

class Orders::DistributeJobTest < JobTestCase
  test "perform calls distribute! on order" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)

      order.define_singleton_method(:all_transfers_generated?) { true }
      Orders::DistributeJob.perform_now(order.trace_id)

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
