class CreateCollectibles < ActiveRecord::Migration[7.0]
  def change
    create_table :collectibles do |t|
      t.uuid :collection_id, index: true
      t.uuid :token_id, index: true
      t.string :identifier
      t.string :name
      t.string :description
      t.string :metahash, index: true
      t.jsonb :metadata

      t.timestamps
    end
  end
end
