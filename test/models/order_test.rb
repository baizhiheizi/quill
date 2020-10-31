# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id         :bigint           not null, primary key
#  item_type  :string
#  order_type :integer
#  state      :string
#  total      :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  buyer_id   :bigint
#  item_id    :bigint
#  seller_id  :bigint
#  trace_id   :uuid
#
# Indexes
#
#  index_orders_on_buyer_id               (buyer_id)
#  index_orders_on_item_type_and_item_id  (item_type,item_id)
#  index_orders_on_seller_id              (seller_id)
#
require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
