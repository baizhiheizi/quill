# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_transactions
#
#  id             :integer          not null, primary key
#  type           :string
#  tx_id          :string
#  block_type     :string
#  hash_str       :string
#  signature      :string
#  block_num      :integer
#  transaction_id :string
#  user_address   :string
#  raw            :jsonb
#  processed_at   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_prs_transactions_on_block_num       (block_num)
#  index_prs_transactions_on_transaction_id  (transaction_id) UNIQUE
#  index_prs_transactions_on_tx_id           (tx_id) UNIQUE
#

require 'test_helper'

class PrsTransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
