class AddNewPinColToMnUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :mixin_network_users, :pin, :string
  end
end
