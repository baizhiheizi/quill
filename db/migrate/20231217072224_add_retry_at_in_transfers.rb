class AddRetryAtInTransfers < ActiveRecord::Migration[7.1]
  def change
    add_column :transfers, :retry_at, :datetime
  end
end
