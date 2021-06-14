class AddRevenueUsdBtcToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :revenue_usd, :decimal, default: 0.0
    add_column :articles, :revenue_btc, :decimal, default: 0.0
    remove_column :articles, :revenue
  end
end
