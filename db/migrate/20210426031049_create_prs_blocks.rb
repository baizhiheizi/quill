class CreatePrsBlocks < ActiveRecord::Migration[6.1]
  def change
    create_table :prs_blocks do |t|
      t.string :type, comment: 'STI'
      t.string :block_id
      t.string :block_type, default: 'PIP:2001'
      t.json :meta
      t.json :data
      t.string :hash
      t.string :signature
      t.integer :block_number
      t.string :block_transation_id
      t.string :user_address
      t.json :raw

      t.timestamps
    end

    add_index :prs_blocks, :block_id, unique: true
    add_index :prs_blocks, :block_number, unique: true
    add_index :prs_blocks, :user_address
  end
end
