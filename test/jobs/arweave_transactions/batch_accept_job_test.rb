# frozen_string_literal: true

require "test_helper"

class ArweaveTransactions::BatchAcceptJobTest < JobTestCase
  test "perform accepts pending arweave transactions" do
    transaction = arweave_transactions(:one)
    called = false
    transaction.define_singleton_method(:accept!) { called = true }

    pending = Object.new
    pending.define_singleton_method(:each) { |&block| [ transaction ].each(&block) }
    pending.define_singleton_method(:map) { |&block| [ transaction ].map(&block) }

    stub_class_method(ArweaveTransaction, :pending, -> { pending }) do
      ArweaveTransactions::BatchAcceptJob.perform_now
    end

    assert called
  end
end
