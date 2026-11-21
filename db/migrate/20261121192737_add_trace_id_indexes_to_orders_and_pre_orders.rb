# frozen_string_literal: true

# trace_id is the lookup key on the payment-critical paths:
# `Orders::DistributeJob` resolves `Order.find_by(trace_id:)` once per
# purchase's revenue distribution (plus the trace-keyed early-reader
# aggregate in `Orders::DistributeService`), and `Purchasable#payment_trace_id`
# probes `PreOrder.exists?(trace_id: ...)` in its dedup loop on every
# purchase. Neither column was indexed, so both lookups seq-scanned.
class AddTraceIdIndexesToOrdersAndPreOrders < ActiveRecord::Migration[8.1]
  def up
    add_index :orders, :trace_id
    add_index :pre_orders, :trace_id
    execute "ANALYZE orders"
    execute "ANALYZE pre_orders"
  end

  def down
    remove_index :orders, :trace_id
    remove_index :pre_orders, :trace_id
  end
end
