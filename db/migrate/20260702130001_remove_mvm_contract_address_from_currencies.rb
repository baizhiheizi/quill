# frozen_string_literal: true

# Drops currencies.mvm_contract_address, the vestigial column that backed
# the (now-shut-down) MVM (Mixin Virtual Machine) payment path. The MVM
# sub-app, mvm_eth auth, MVMPreOrder, and related JS/controllers were
# removed in Phase 1 (#1795); no code path reads or writes this column
# anymore. Part of the legacy cleanup tracked in #1790 / #1798.
class RemoveMvmContractAddressFromCurrencies < ActiveRecord::Migration[8.1]
  def change
    remove_column :currencies, :mvm_contract_address, :string
  end
end
