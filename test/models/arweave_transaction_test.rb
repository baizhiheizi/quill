# frozen_string_literal: true

# == Schema Information
#
# Table name: arweave_transactions
#
#  id                  :bigint           not null, primary key
#  article_uuid        :uuid
#  raw                 :json
#  state               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  article_snapshot_id :bigint
#  order_id            :bigint
#  owner_id            :uuid
#  tx_id               :string
#
# Indexes
#
#  index_arweave_transactions_on_article_snapshot_id  (article_snapshot_id)
#  index_arweave_transactions_on_article_uuid         (article_uuid)
#  index_arweave_transactions_on_order_id             (order_id)
#  index_arweave_transactions_on_owner_id             (owner_id)
#  index_arweave_transactions_on_tx_id                (tx_id)
#
require 'test_helper'

class ArweaveTransactionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
