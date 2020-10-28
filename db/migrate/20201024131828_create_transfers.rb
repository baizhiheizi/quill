class CreateTransfers < ActiveRecord::Migration[6.0]
  def change
    create_table :transfers do |t|
      t.belongs_to :source, polymorphic: true
      t.integer :transfer_type
      t.decimal :amount
      t.uuid :trace_id
      t.uuid :asset_id
      t.uuid :opponent_id
      t.string :memo
      t.datetime :processed_at
      t.json :snapshot

      t.timestamps
    end

    add_index :transfers, :trace_id, unique: true
  end
end
