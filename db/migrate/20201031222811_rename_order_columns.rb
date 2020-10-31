class RenameOrderColumns < ActiveRecord::Migration[6.0]
  def change
    rename_column :orders, :payer_id, :buyer_id
    rename_column :orders, :receiver_id, :seller_id
  end
end
