# frozen_string_literal: true

require "test_helper"

class TransferTest < ActiveSupport::TestCase
  test "transfer_type enum includes revenue types" do
    assert_includes Transfer.transfer_types.keys, "author_revenue"
    assert_includes Transfer.transfer_types.keys, "reader_revenue"
    assert_includes Transfer.transfer_types.keys, "quill_revenue"
  end

  test "requires amount and trace_id" do
    transfer = Transfer.new

    assert_not transfer.valid?
    assert transfer.errors[:amount].present? || transfer.errors[:trace_id].present?
  end
end
