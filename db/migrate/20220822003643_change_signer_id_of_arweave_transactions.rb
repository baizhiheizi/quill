class ChangeSignerIdOfArweaveTransactions < ActiveRecord::Migration[7.0]
  def change
    rename_column :arweave_transactions, :signer_id, :owner_id
  end
end
