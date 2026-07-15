# frozen_string_literal: true

class AddCompoundUniqueIndexToOrders < ActiveRecord::Migration[8.1]
  def change
    add_index :orders,
      %i[order_type buyer_id item_type item_id],
      unique: true,
      where: "order_type IN (0, 3)",
      name: "idx_orders_buyer_item_type_unique"
  end
end
