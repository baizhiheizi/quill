# frozen_string_literal: true

class DropArweaveTransactions < ActiveRecord::Migration[8.1]
  def up
    drop_table :arweave_transactions, if_exists: true
  end

  def down
    create_table :arweave_transactions do |t|
      t.belongs_to :article_snapshot
      t.uuid :article_uuid
      t.string :digest
      t.bigint :order_id
      t.uuid :owner_id
      t.json :raw
      t.string :state
      t.string :tx_id

      t.timestamps
    end

    add_index :arweave_transactions, :article_snapshot_id
    add_index :arweave_transactions, %i[article_uuid owner_id digest],
              name: "index_ar_tx_on_article_uuid_and_owner_id_and_digest", unique: true
    add_index :arweave_transactions, :order_id
    add_index :arweave_transactions, :owner_id
    add_index :arweave_transactions, :tx_id
  end
end
