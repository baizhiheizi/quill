class ChangeUsersBannedToValidated < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :banned_at, :datetime
    add_column :users, :validated_at, :datetime
  end
end
