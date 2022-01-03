class AddCreatedAtIndexToTransfers < ActiveRecord::Migration[7.0]
  def change
    add_index :transfers, :created_at
  end
end
