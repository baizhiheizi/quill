class AddBlocksCountToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :blocks_count, :integer, default: 0
    add_column :users, :blocking_count, :integer, default: 0
  end
end
