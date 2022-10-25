class ModifyCollectionAndCollecible < ActiveRecord::Migration[7.0]
  def change
    remove_column :collections, :creator_id, :uuid
    remove_column :collections, :author_id, :integer

    add_column :collections, :author_id, :uuid
    add_index :collections, :author_id

    add_column :collections, :price, :decimal
    add_column :collections, :asset_id, :uuid
    add_column :collections, :revenue_ratio, :float, default: 0.2
    add_column :collections, :symbol, :string

    remove_column :articles, :collection_id, :bigint
    add_column :articles, :collection_id, :uuid
    add_index :articles, :collection_id
    add_column :articles, :collection_revenue_ratio, :float, default: 0.0

    remove_column :collectibles, :description, :text
  end
end
