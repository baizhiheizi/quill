class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :users do |t|
      t.string :name
      t.string :avatar_url
      t.string :mixin_id
      t.uuid :mixin_uuid

      t.timestamps
    end

    add_index :users, :mixin_id, unique: true
    add_index :users, :mixin_uuid, unique: true
  end
end
