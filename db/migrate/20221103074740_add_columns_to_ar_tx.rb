class AddColumnsToArTx < ActiveRecord::Migration[7.0]
  def change
    add_column :arweave_transactions, :hash, :string

    remove_index :arweave_transactions, :article_uuid
    add_index :arweave_transactions, %i[article_uuid hash], unique: true
  end
end
