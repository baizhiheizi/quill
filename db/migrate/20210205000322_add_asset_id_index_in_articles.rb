class AddAssetIdIndexInArticles < ActiveRecord::Migration[6.1]
  def change
    add_index :articles, :asset_id
    add_index :orders, :asset_id
    add_index :payments, :asset_id
    add_index :transfers, :asset_id
  end
end
