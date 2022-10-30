class RenameCollectionsColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :collections, :order_count, :orders_count
  end
end
