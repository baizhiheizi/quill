class RemovePrsModels < ActiveRecord::Migration[7.0]
  def change
    drop_table :prs_account, if_exists: true
    drop_table :prs_transaction, if_exists: true
  end
end
