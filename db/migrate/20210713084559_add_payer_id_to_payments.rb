class AddPayerIdToPayments < ActiveRecord::Migration[6.1]
  def change
    add_column :payments, :payer_id, :uuid
    add_index :payments, :opponent_id
    add_index :payments, :payer_id
  end
end
