class CreateSwapOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :swap_orders do |t|
      t.belongs_to :payment
      t.uuid :trace_id
      t.uuid :user_id
      t.string :state
      t.uuid :pay_asset_id, comment: 'paid asset'
      t.uuid :fill_asset_id, comment: 'swapped asset'
      t.decimal :funds, comment: 'paid amount'
      t.decimal :amount, comment: 'swapped amount'
      t.decimal :min_amount, comment: 'minimum swapped amount'
      t.json :raw, comment: 'raw order response'

      t.timestamps
    end

    add_index :swap_orders, :trace_id, unique: true
    add_index :swap_orders, :user_id
  end
end
