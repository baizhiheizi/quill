class AddAssetIdToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :asset_id, :uuid 
    add_column :orders, :price_usd, :decimal
    add_column :orders, :price_btc, :decimal

    Order.find_each do |order|
      next if order.asset_id.present?

      order.update asset_id: order.item.asset_id
    end
  end
end
