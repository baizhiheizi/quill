class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.belongs_to :user
      t.uuid :uuid, index: { unique: true }
      t.json :info

      t.timestamps
    end
  end
end
