class CreateNftCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :nft_collections do |t|
      t.uuid :uuid, index: { unique: true }
      t.uuid :creator_id
      t.jsonb :raw

      t.timestamps
    end
  end
end
