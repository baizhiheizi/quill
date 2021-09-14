class RemoveMixinIdIndexUnique < ActiveRecord::Migration[6.1]
  def change
    remove_index :users, :mixin_id
    add_index :users, :mixin_id
  end
end
