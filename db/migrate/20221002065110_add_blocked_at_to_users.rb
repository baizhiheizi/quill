class AddBlockedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :blocked_at, :datetime
  end
end
