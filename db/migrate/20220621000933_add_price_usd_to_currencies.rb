class AddPriceUsdToCurrencies < ActiveRecord::Migration[7.0]
  def change
    add_column :currencies, :price_usd, :decimal
    add_column :currencies, :price_btc, :decimal
  end
end
