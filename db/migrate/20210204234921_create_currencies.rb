class CreateCurrencies < ActiveRecord::Migration[6.1]
  def change
    create_table :currencies do |t|
      t.uuid :asset_id, index: { unique: true }
      t.jsonb :raw

      t.timestamps
    end
  end
end
