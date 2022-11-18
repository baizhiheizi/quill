class AddMVMContractToCurrencies < ActiveRecord::Migration[7.0]
  def change
    add_column :currencies, :mvm_contract_address, :string
  end
end
