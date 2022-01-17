class AddIndexesToSnapshots < ActiveRecord::Migration[7.0]
  def change
    add_index :mixin_network_snapshots, :processed_at
    add_index :mixin_network_snapshots, :created_at
  end
end
