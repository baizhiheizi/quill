class AddIndexToTransfers < ActiveRecord::Migration[7.0]
  def change
    add_index :transfers, :processed_at
  end
end
