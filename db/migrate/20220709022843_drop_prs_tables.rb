class DropPrsTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :prs_accounts, if_exists: true
    drop_table :prs_transactions, if_exists: true
  end
end
