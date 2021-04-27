# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_accounts
#
#  id                    :bigint           not null, primary key
#  account               :string
#  encrypted_private_key :string
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
end
