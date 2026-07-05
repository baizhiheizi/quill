# frozen_string_literal: true

require "test_helper"

class Transfers::ProcessJobTest < JobTestCase
  test "perform calls process_with_rescue! on transfer" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one), total: 1.0)
      distribute_order!(order)
      transfer = order.transfers.first
      processed = false

      Transfer.define_singleton_method(:find_by) do |trace_id:|
        next unless trace_id == transfer.trace_id

        transfer.define_singleton_method(:process_with_rescue!) { processed = true }
        transfer
      end

      Transfers::ProcessJob.perform_now(transfer.trace_id)

      assert processed
    end
  ensure
    Transfer.singleton_class.remove_method(:find_by) if Transfer.singleton_class.method_defined?(:find_by)
  end

  test "limits concurrency per trace_id and discards duplicate enqueues" do
    assert_equal 1, Transfers::ProcessJob.concurrency_limit
    assert_equal :discard, Transfers::ProcessJob.concurrency_on_conflict
  end
end
