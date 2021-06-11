class ChangeColumnInOrders < ActiveRecord::Migration[6.1]
  def change
    rename_column :orders, :change_btc, :value_btc
    rename_column :orders, :change_usd, :value_usd
  end
end
