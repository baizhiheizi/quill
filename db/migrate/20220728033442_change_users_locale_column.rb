class ChangeUsersLocaleColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :locale
    add_column :users, :locale, :string
  end
end
