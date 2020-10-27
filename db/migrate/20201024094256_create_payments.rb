class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.uuid :opponent_id
      t.uuid :trace_id
      t.uuid :snapshot_id
      t.uuid :asset_id
      t.decimal :amount
      t.string :memo
      t.string :state
      t.json :raw

      t.timestamps
    end

    add_index :payments, :trace_id, unique: true
  end
end
