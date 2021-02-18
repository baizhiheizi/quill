class CreateUserAccessTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :user_access_tokens do |t|
      t.belongs_to :user
      t.uuid :value, index: { unique: true }
      t.string :memo, null: false

      t.timestamps
    end
  end
end
