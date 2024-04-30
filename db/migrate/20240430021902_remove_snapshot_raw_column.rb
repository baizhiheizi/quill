class RemoveSnapshotRawColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :mixin_network_snapshots, :raw
  end
end
