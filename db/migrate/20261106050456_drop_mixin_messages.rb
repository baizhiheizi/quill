class DropMixinMessages < ActiveRecord::Migration[8.1]
  # The inbound-message ingest path (MixinMessage / MixinMessages::ProcessJob)
  # was retired with the Blaze reactor; nothing reads or writes this table.
  def up
    drop_table :mixin_messages
  end

  def down
    create_table :mixin_messages do |t|
      t.string :action
      t.string :category
      t.string :content, comment: "decrepted data"
      t.uuid :conversation_id
      t.uuid :message_id
      t.datetime :processed_at, precision: nil
      t.json :raw
      t.string :state
      t.uuid :user_id
      t.timestamps
      t.index :message_id, name: "index_mixin_messages_on_message_id", unique: true
    end
  end
end
