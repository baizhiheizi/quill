class ModifyCollectionAndCollecible < ActiveRecord::Migration[7.0]
  def change
    remove_column :collections, :creator_id, :uuid
    remove_column :collections, :author_id, :integer

    add_column :collections, :author_id, :uuid
    add_index :collections, :author_id
    add_column :collections, :price, :decimal
    add_column :collections, :asset_id, :uuid
    add_column :collections, :revenue_ratio, :uuid

    remove_column :articles, :collection_id, :bigint
    add_column :articles, :collection_id, :uuid
    add_index :articles, :collection_id

    remove_column :collectibles, :description, :text
  end
end
