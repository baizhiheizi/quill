# frozen_string_literal: true

# == Schema Information
#
# Table name: transfers
#
#  id            :bigint           not null, primary key
#  memo          :string
#  processed_at  :datetime
#  snapshot      :json
#  transfer_type :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  asset_id      :uuid
#  opponent_id   :uuid
#  order_id      :bigint
#  trace_id      :uuid
#
# Indexes
#
#  index_transfers_on_order_id  (order_id)
#  index_transfers_on_trace_id  (trace_id) UNIQUE
#
require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
