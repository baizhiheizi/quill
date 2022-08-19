class AddPublicKeyToUserAuthorizations < ActiveRecord::Migration[7.0]
  def change
    add_column :user_authorizations, :public_key, :string
  end
end
