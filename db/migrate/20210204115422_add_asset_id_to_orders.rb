class AddAssetIdToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :asset_id, :uuid 
  end
end
