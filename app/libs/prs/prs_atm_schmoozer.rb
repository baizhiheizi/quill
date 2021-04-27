# frozen_string_literal: true

module Prs
  class PrsAtmSchmoozer < Schmooze::Base
    dependencies prsAtm: 'prs-atm'

    method :create_keystore, 'prsAtm.wallet.createKeystore'
    method :recover_private_key, 'prsAtm.wallet.recoverPrivateKey'
    method :open_free_account, 'prsAtm.atm.openFreeAccount'
    method :hash, 'prsAtm.encryption.hash'
    method :sign, 'prsAtm.prsc.signSave'
  end
end
