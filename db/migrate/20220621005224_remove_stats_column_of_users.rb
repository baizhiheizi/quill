class RemoveStatsColumnOfUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :statistics
  end
end
