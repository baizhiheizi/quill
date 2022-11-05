class EditArTxIndex < ActiveRecord::Migration[7.0]
  def change
    remove_column :arweave_transactions, :hash, if_exists: true
    add_column :arweave_transactions, :digest, if_exists: true
    remove_index :arweave_transactions, %i[article_uuid digest], name: :index_arweave_transactions_on_article_uuid_and_digest, unique: true, if_exists: true

    add_index :arweave_transactions, %i[article_uuid owner_id digest], name: :index_ar_tx_on_article_uuid_and_owner_id_and_digest, unique: true
  end
end
