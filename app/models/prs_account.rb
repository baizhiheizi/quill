# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_accounts
#
#  id                    :bigint           not null, primary key
#  account               :string
#  encrypted_private_key :string
#  keystore              :json
#  public_key            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint
#
# Indexes
#
#  index_prs_accounts_on_account  (account) UNIQUE
#  index_prs_accounts_on_user_id  (user_id)
#
class PrsAccount < ApplicationRecord
  include Encryptable

  attr_encrypted :private_key

  belongs_to :user

  has_many :blocks, class_name: 'PrsBlock', primary_key: :account, foreign_key: :user_address, dependent: :restrict_with_error, inverse_of: :prs_account

  before_validation :set_defaults, on: :create
  after_commit :register_on_chain_async, on: :create

  def registered?
    account.present?
  end

  def register_on_chain!
    r = Prs.api.open_free_account public_key, private_key
    update! account: r['account']
  end

  def register_on_chain_async
    PrsAccountRegisterOnChainWorker.perform_async id
  end

  private

  def set_defaults
    return unless new_record?

    keystore = Prs.api.create_keystore
    private_key = Prs.api.recover_private_key keystore
    assign_attributes(
      keystore: keystore,
      public_key: keystore['publickey'],
      private_key: private_key
    )
  end
end
