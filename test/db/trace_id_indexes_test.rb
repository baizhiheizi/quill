# frozen_string_literal: true

require "test_helper"

# `orders.trace_id` is looked up by `Orders::DistributeJob`
# (`Order.find_by(trace_id:)`) and by `Payment`'s trace-keyed `has_one :order`
# (every `payment.order` load runs `WHERE orders.trace_id = ?`).
# `pre_orders.trace_id` is probed by `Purchasable#payment_trace_id`'s dedup
# loop (`PreOrder.exists?(trace_id: ..., state: ...)`).
#
# The indexes are invisible to the models, so nothing fails when one goes
# away — the payment path just gets slower. This test is the guard.
class TraceIdIndexesTest < ActiveSupport::TestCase
  test "orders is indexed on trace_id" do
    index = index_for(:orders, "index_orders_on_trace_id")

    assert_not_nil index, "orders lost its trace_id index"
    assert_equal %w[trace_id], index.columns
  end

  test "pre_orders is indexed on trace_id" do
    index = index_for(:pre_orders, "index_pre_orders_on_trace_id")

    assert_not_nil index, "pre_orders lost its trace_id index"
    assert_equal %w[trace_id], index.columns
  end

  private

  def index_for(table, name)
    ActiveRecord::Base.connection.indexes(table).find { |index| index.name == name }
  end
end
