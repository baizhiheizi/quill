class AddIndexex < ActiveRecord::Migration[6.1]
  def change
    add_index :transfers, :opponent_id
    add_index :transfers, :transfer_type
  end
end
