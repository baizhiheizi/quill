class CreatePrsTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :prs_transactions do |t|
      t.string :type, comment: 'STI'
      t.string :tx_id
      t.string :block_type
      t.string :hash_str
      t.string :signature
      t.integer :block_num
      t.string :transaction_id
      t.string :user_address
      t.jsonb :raw
      t.datetime :processed_at

      t.timestamps
    end

    add_index :prs_transactions, :block_num, unique: true
    add_index :prs_transactions, :tx_id, unique: true
    add_index :prs_transactions, :transaction_id, unique: true
  end
end
