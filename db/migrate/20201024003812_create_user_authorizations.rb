class CreateUserAuthorizations < ActiveRecord::Migration[6.0]
  def change
    create_table :user_authorizations do |t|
      t.belongs_to :user
      t.integer :provider, comment: 'third party auth provider'
      t.string :uid, comment: 'third party user id'
      t.string :access_token
      t.json :raw, comment: 'third pary user info'

      t.timestamps
    end

    add_index :user_authorizations, [:provider, :uid], unique: true
  end
end
