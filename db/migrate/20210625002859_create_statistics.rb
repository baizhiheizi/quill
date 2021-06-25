class CreateStatistics < ActiveRecord::Migration[6.1]
  def change
    create_table :statistics do |t|
      t.string :type
      t.datetime :datetime
      t.jsonb :data

      t.timestamps
    end
  end
end
