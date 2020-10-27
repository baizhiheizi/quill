class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.belongs_to :receiver
      t.belongs_to :payer
      t.references :item, polymorphic: true
      t.uuid :trace_id
      t.string :state
      t.integer :order_type
      t.decimal :total

      t.timestamps
    end
  end
end
