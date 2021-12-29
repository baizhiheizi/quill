# frozen_string_literal: true

# == Schema Information
#
# Table name: swap_orders
#
#  id            :integer          not null, primary key
#  payment_id    :integer
#  trace_id      :uuid
#  user_id       :uuid
#  state         :string
#  pay_asset_id  :uuid
#  fill_asset_id :uuid
#  funds         :decimal(, )
#  amount        :decimal(, )
#  min_amount    :decimal(, )
#  raw           :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_swap_orders_on_payment_id  (payment_id)
#  index_swap_orders_on_trace_id    (trace_id) UNIQUE
#  index_swap_orders_on_user_id     (user_id)
#

require 'test_helper'

class SwapOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
