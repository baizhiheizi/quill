# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id          :integer          not null, primary key
#  opponent_id :uuid
#  trace_id    :uuid
#  snapshot_id :uuid
#  asset_id    :uuid
#  amount      :decimal(, )
#  memo        :string
#  state       :string
#  raw         :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  payer_id    :uuid
#
# Indexes
#
#  index_payments_on_asset_id     (asset_id)
#  index_payments_on_opponent_id  (opponent_id)
#  index_payments_on_payer_id     (payer_id)
#  index_payments_on_trace_id     (trace_id) UNIQUE
#

require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
