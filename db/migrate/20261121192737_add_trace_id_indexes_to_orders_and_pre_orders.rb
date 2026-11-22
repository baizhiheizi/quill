# frozen_string_literal: true

# trace_id is the lookup key on the payment-critical paths:
# `Orders::DistributeJob` resolves `Order.find_by(trace_id:)` once per
# purchase's revenue distribution; `Payment`'s trace-keyed `has_one :order`
# (behind `find_or_create_by!(payment: ...)` in
# `Payment#place_article_order!`/`place_collection_order!`) runs
# `WHERE orders.trace_id = ?` on every purchase; and
# `Purchasable#payment_trace_id` probes `PreOrder.exists?(trace_id: ...)` in
# its dedup loop on every purchase. Neither column was indexed, so all of
# these lookups seq-scanned. (The early-reader share aggregate in
# `Orders::DistributeService` groups *by* trace_id but does not filter on it,
# so it is served by `index_orders_on_item_type_and_item_id` instead.)
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
