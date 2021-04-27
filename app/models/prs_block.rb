# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_blocks
#
#  id                    :bigint           not null, primary key
#  block_number          :integer
#  block_type            :string           default("PIP:2001")
#  data                  :json
#  hash                  :string
#  meta                  :json
#  raw                   :json
#  signature             :string
#  type(STI)             :string
#  user_address          :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  block_id              :string
#  block_transation_id   :string
#
# Indexes
#
#  index_prs_blocks_on_block_id      (block_id) UNIQUE
#  index_prs_blocks_on_block_number  (block_number) UNIQUE
#  index_prs_blocks_on_user_address  (user_address)
#
class PrsBlock < ApplicationRecord
  belongs_to :prs_account, primary_key: :account, foreign_key: :user_address, inverse_of: :blocks
end
