# frozen_string_literal: true

class AddCompoundUniqueIndexToOrders < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        # Deduplicate orders before adding the unique index.
        # For each (order_type, buyer_id, item_type, item_id) group where
        # order_type is buy_article (0) or buy_collection (3),
        # keep only the most recent "completed" order (or most recent if none completed).
        execute <<-SQL.squish
          WITH ranked AS (
            SELECT id,
                   ROW_NUMBER() OVER (
                     PARTITION BY order_type, buyer_id, item_type, item_id
                     ORDER BY
                       CASE WHEN state = 'completed' THEN 0 ELSE 1 END,
                       created_at DESC,
                       id DESC
                   ) AS rn
            FROM orders
            WHERE order_type IN (0, 3)
          ),
          to_delete AS (
            SELECT id FROM ranked WHERE rn > 1
          ),
          nullified AS (
            UPDATE transfers
            SET source_id = NULL, source_type = NULL
            WHERE source_type = 'Order'
              AND source_id IN (SELECT id FROM to_delete)
          ),
          deleted_events AS (
            DELETE FROM noticed_events
            WHERE record_type = 'Order'
              AND record_id IN (SELECT id FROM to_delete)
            RETURNING id
          )
          DELETE FROM noticed_notifications
          WHERE event_id IN (SELECT id FROM deleted_events)
        SQL

        execute <<-SQL.squish
          WITH ranked AS (
            SELECT id,
                   ROW_NUMBER() OVER (
                     PARTITION BY order_type, buyer_id, item_type, item_id
                     ORDER BY
                       CASE WHEN state = 'completed' THEN 0 ELSE 1 END,
                       created_at DESC,
                       id DESC
                   ) AS rn
            FROM orders
            WHERE order_type IN (0, 3)
          )
          DELETE FROM orders
          WHERE id IN (SELECT id FROM ranked WHERE rn > 1)
        SQL
      end
    end

    add_index :orders,
      %i[order_type buyer_id item_type item_id],
      unique: true,
      where: "order_type IN (0, 3)",
      name: "idx_orders_buyer_item_type_unique"
  end
end
