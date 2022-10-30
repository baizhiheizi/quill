class AddSourceToCollectibles < ActiveRecord::Migration[7.0]
  def change
    add_column :collectibles, :source_type, :string
    add_column :collectibles, :source_id, :bigint
    add_index :collectibles, %i[source_type source_id], unique: true
  end
end
