class AddQueueToTransfers < ActiveRecord::Migration[6.1]
  def change
    add_column :transfers, :queue_priority, :integer, default: 0
  end
end
