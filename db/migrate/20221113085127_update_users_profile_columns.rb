class UpdateUsersProfileColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :avatar_url, :string
    add_column :users, :biography, :text
  end
end
