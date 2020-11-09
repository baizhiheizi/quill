class CreateAnnouncements < ActiveRecord::Migration[6.0]
  def change
    create_table :announcements do |t|
      t.string :message_type
      t.text :content
      t.string :state
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
