class CreatePrsAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :prs_accounts do |t|
      t.belongs_to :user

      t.string :account
      t.string :public_key
      t.string :encrypted_private_key

      t.timestamps
    end

    add_index :prs_accounts, :account, unique: true
  end
end
