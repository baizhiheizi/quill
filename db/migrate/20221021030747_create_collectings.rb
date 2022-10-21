class CreateCollectings < ActiveRecord::Migration[7.0]
  def change
    create_table :collectings do |t|
      t.bigint :collection_id
      t.bigint :nft_collection_id

      t.timestamps
    end

    add_index :collectings, %i[collection_id nft_collection_id], unique: true
  end
end
