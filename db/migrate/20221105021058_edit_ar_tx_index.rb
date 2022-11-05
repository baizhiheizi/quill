class EditArTxIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :arweave_transactions, %i[article_uuid digest], unique: true

    add_index :arweave_transactions, %i[article_uuid owner_id digest], name: :index_ar_tx_on_article_uuid_and_owner_id_and_digest, unique: true
  end
end
