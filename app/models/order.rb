# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id          :bigint           not null, primary key
#  item_type   :string
#  order_type  :integer
#  state       :string
#  total       :decimal(, )
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  item_id     :bigint
#  payer_id    :bigint
#  receiver_id :bigint
#  trace_id    :uuid
#
# Indexes
#
#  index_orders_on_item_type_and_item_id  (item_type,item_id)
#  index_orders_on_payer_id               (payer_id)
#  index_orders_on_receiver_id            (receiver_id)
#
class Order < ApplicationRecord
  belongs_to :payer, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :item, polymorphic: true

  has_one :payment, foreign_key: :trace_id, primary_key: :trace_id, dependent: :nullify, inverse_of: false
end
