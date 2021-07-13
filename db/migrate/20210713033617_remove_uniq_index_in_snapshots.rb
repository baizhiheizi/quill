class RemoveUniqIndexInSnapshots < ActiveRecord::Migration[6.1]
  def change
    remove_index :mixin_network_snapshots, :trace_id

    add_index :mixin_network_snapshots, :trace_id
    add_index :mixin_network_snapshots, :snapshot_id, unique: true
  end
end
