class CreatePreOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :pre_orders do |t|
      t.belongs_to :item, polymorphic: true
      t.uuid :payer_id, index: true
      t.uuid :payee_id, index: true
      t.string :type
      t.string :order_type
      t.decimal :amount
      t.uuid :asset_id
      t.uuid :trace_id
      t.string :state
      t.string :memo
      t.json :result

      t.timestamps
    end
  end
end
