class AddOpponentMultisigToTransfers < ActiveRecord::Migration[6.1]
  def change
    add_column :transfers, :opponent_multisig, :json, default: {}
  end
end
