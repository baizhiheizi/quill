class AddUidToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :uid, :string
    add_index :users, :uid, unique: true

    User.find_each do |user|
      user.update uid: user.mixin_id
    end
  end
end
