class DropAnnouncements < ActiveRecord::Migration[8.1]
  def change
    drop_table :announcements do |t|
      t.text :content
      t.string :message_type
      t.string :state
      t.datetime :delivered_at
      t.timestamps
    end
  end
end
