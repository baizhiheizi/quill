class AddCiterIdToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :citer_id, :integer
    add_column :orders, :citer_type, :string
    add_index :orders, [:citer_type, :citer_id]
  end
end
