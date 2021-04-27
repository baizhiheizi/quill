# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_transactions
#
#  id              :bigint           not null, primary key
#  block_num       :integer
#  block_type      :string
#  data            :jsonb
#  hash_str        :string
#  meta            :jsonb
#  raw             :jsonb
#  signature       :string
#  type(STI)       :string
#  user_address    :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  transation_id   :string
#  tx_id           :string
#
# Indexes
#
#  index_prs_transactions_on_block_num      (block_num) UNIQUE
#  index_prs_transactions_on_transation_id  (transation_id) UNIQUE
#  index_prs_transactions_on_tx_id          (tx_id) UNIQUE
#
class PrsTransaction < ApplicationRecord
  before_validation :set_defaults, on: :create

  validates :raw, presence: true

  def validate_on_chain
  end

  def set_defaults
    return unless new_record?

    assign_attributes(
      tx_id: raw['id'],
      block_type: raw['type'],
      hash_str: raw['hash'],
      signature: raw['signature'],
      user_address: raw['user_address'],
      meta: JSON.parse(raw['meta']),
      data: JSON.parse(raw['data'])
    )
  end
end
