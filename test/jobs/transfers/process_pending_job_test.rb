# frozen_string_literal: true

require "test_helper"

class Transfers::ProcessPendingJobTest < JobTestCase
  test "perform delegates to Transfer.process_pending!" do
    called = false
    stub_class_method(Transfer, :process_pending!, -> { called = true }) do
      Transfers::ProcessPendingJob.perform_now
    end

    assert called
  end

  test "limits concurrency to one sweep at a time" do
    assert_equal 1, Transfers::ProcessPendingJob.concurrency_limit
    assert_equal :block, Transfers::ProcessPendingJob.concurrency_on_conflict
  end
end
