# frozen_string_literal: true

# Drops the swap_orders table that backed the (now-shut-down) 4swap / Pando
# Lake cross-asset payment path. The model, controllers, jobs, notifiers,
# and views were removed in Phase 0 (#1799); only the dormant table rows
# remained. Part of the legacy cleanup tracked in #1790 / #1798.
class DropSwapOrders < ActiveRecord::Migration[8.1]
  def up
    drop_table :swap_orders, if_exists: true
  end

  def down
    create_table :swap_orders do |t|
      t.belongs_to :payment
      t.uuid :trace_id
      t.uuid :user_id
      t.string :state
      t.uuid :pay_asset_id, comment: "paid asset"
      t.uuid :fill_asset_id, comment: "swapped asset"
      t.decimal :funds, comment: "paid amount"
      t.decimal :amount, comment: "swapped amount"
      t.decimal :min_amount, comment: "minimum swapped amount"
      t.json :raw, comment: "raw order response"

      t.timestamps
    end
    add_index :swap_orders, :trace_id, unique: true
    add_index :swap_orders, :user_id
  end
end
