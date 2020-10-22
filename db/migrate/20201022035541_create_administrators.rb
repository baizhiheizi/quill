class CreateAdministrators < ActiveRecord::Migration[6.0]
  def change
    create_table :administrators do |t|
      t.string :name, null: false
      t.string :password_digest, null: false
      t.timestamps
    end

    add_index :administrators, :name, unique: true
  end
end
