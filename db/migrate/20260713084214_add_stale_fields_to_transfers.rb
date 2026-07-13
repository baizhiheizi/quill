class AddStaleFieldsToTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :transfers, :stale_at, :datetime
    add_column :transfers, :staled_by_id, :bigint
    add_index :transfers, [ :processed_at, :stale_at ]
  end
end
