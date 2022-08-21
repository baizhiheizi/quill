class CreateArweaveTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :arweave_transactions do |t|
      t.belongs_to :article_snapshot
      t.belongs_to :order
      t.uuid :article_uuid, index: true
      t.uuid :owner_id, index: true
      t.string :tx_id, index: true
      t.string :state
      t.json :raw

      t.timestamps
    end
  end
end
