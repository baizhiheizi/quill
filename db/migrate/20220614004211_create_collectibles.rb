class CreateCollectibles < ActiveRecord::Migration[7.0]
  def change
    create_table :collectibles do |t|
      t.uuid :collection_id
      t.uuid :token_id, index: { unique: true }
      t.string :identifier
      t.string :name
      t.string :description
      t.string :state
      t.string :metahash, index: { unique: true }
      t.jsonb :metadata

      t.timestamps
    end

    add_index :collectibles, %i[collection_id identifier], unique: true
  end
end
