class CreateBonuses < ActiveRecord::Migration[6.0]
  def change
    create_table :bonuses do |t|
      t.belongs_to :user
      t.string :title
      t.text :description
      t.string :state
      t.string :asset_id
      t.decimal :amount
      t.uuid :trace_id

      t.timestamps
    end

    add_index :bonuses, :trace_id, unique: true
  end
end
