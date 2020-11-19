class CreateMixinNetworkUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :mixin_network_users do |t|
      t.belongs_to :owner, polymorphic: true
      t.uuid :uuid
      t.string :name
      t.uuid :session_id
      t.string :pin_token
      t.json :raw
      t.string :private_key
      t.string :encrypted_pin

      t.timestamps
    end

    add_index :mixin_network_users, :uuid, unique: true
  end
end
