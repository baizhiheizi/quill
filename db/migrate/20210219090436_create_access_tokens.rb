class CreateAccessTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :access_tokens do |t|
      t.belongs_to :user
      t.uuid :value, index: { unique: true }
      t.string :memo
      t.jsonb :last_request
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
