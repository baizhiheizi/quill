class RemovePrsTransactionBlockNumIndexUnique < ActiveRecord::Migration[6.1]
  def change
    remove_index :prs_transactions, :block_num
    add_index :prs_transactions, :block_num
  end
end
