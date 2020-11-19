class AddWalletIdToTransfers < ActiveRecord::Migration[6.0]
  def change
    add_column :transfers, :wallet_id, :uuid
    add_index :transfers, :wallet_id
  end
end
