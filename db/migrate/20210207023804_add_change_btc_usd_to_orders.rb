class AddChangeBtcUsdToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :change_btc, :decimal
    add_column :orders, :change_usd, :decimal
  end
end
