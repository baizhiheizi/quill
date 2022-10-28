class AddOrdersCountToCollections < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :order_count, :integer, default: 0
  end
end
