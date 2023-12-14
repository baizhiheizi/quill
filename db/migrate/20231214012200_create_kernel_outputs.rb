class CreateKernelOutputs < ActiveRecord::Migration[7.1]
  def change
    create_table :kernel_outputs do |t|
      t.uuid :asset_id, index: true
      t.decimal :amount
      t.string :state

      t.json :raw

      t.timestamps
    end
  end
end
