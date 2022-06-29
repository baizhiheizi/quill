class AddChainIdToCurrencies < ActiveRecord::Migration[7.0]
  def change
    add_column :currencies, :chain_id, :uuid, index: true
    add_column :currencies, :symbol, :string

    Currency.all.each do |currency|
      currency.update chain_id: currency.raw['chain_id']
      currency.update symbol: currency.raw['symbol']
    end
  end
end
