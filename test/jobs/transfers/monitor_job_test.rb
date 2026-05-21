# frozen_string_literal: true

require "test_helper"

class Transfers::MonitorJobTest < JobTestCase
  test "perform completes when stale unprocessed transfers exist" do
    with_quill_bot_stub do
      order = create_buy_order!(article: articles(:published_paid), buyer: users(:reader_one))
      distribute_order!(order)
      transfer = order.transfers.first
      transfer.update!(created_at: 13.hours.ago, processed_at: nil)

      assert_nothing_raised { Transfers::MonitorJob.perform_now }
    end
  end
end
