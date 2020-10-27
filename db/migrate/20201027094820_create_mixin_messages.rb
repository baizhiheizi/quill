class CreateMixinMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :mixin_messages do |t|
      t.string :action
      t.string :category
      t.uuid :user_id
      t.uuid :conversation_id
      t.uuid :message_id
      t.string :content, comment: 'decrepted data'
      t.json :raw
      t.datetime :processed_at
      t.string :state

      t.timestamps
    end

    add_index :mixin_messages, :message_id, unique: true
  end
end
