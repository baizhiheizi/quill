class CreateArticleSnapshots < ActiveRecord::Migration[6.1]
  def change
    create_table :article_snapshots do |t|
      t.uuid :article_uuid
      t.json :raw
      t.string :file_hash
      t.string :tx_id
      t.text :file_content
      t.string :state
      t.datetime :requested_at
      t.datetime :signed_at

      t.timestamps
    end

    add_index :article_snapshots, :tx_id, unique: true
    add_index :article_snapshots, :article_uuid
  end
end
