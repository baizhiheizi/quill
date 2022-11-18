class AddUniqueOutputIdIndexNfos < ActiveRecord::Migration[7.0]
  def change
    add_index :non_fungible_outputs, :output_id, unique: true
  end
end
