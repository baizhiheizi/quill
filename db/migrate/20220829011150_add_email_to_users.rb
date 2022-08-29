class AddEmailToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :email, :string
    add_column :users, :email_verified_at, :datetime

    add_index :users, :email, unique: true
  end
end
