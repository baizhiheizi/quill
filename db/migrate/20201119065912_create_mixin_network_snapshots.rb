class CreateMixinNetworkSnapshots < ActiveRecord::Migration[6.0]
  def change
    create_table :mixin_network_snapshots do |t|
      t.uuid :user_id
      t.uuid :trace_id
      t.uuid :opponent_id
      t.string :data
      t.uuid :snapshot_id
      t.decimal :amount
      t.uuid :asset_id
      t.datetime :transferred_at
      t.json :raw
      t.datetime :processed_at

      t.timestamps
    end

    add_index :mixin_network_snapshots, :user_id
    add_index :mixin_network_snapshots, :trace_id, unique: true
  end
end
