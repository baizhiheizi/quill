class AddTypeToMixinNetworkUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :mixin_network_users, :type, :string
  end
end
