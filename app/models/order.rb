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
  include AASM

  belongs_to :payer, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :item, polymorphic: true

  has_many :transfers, as: :source, dependent: :nullify
  has_one :payment, foreign_key: :trace_id, primary_key: :trace_id, dependent: :nullify, inverse_of: :order

  before_validation :setup_attributes

  validate :ensure_total_sufficient

  enum order_type: { buy_article: 0, reward_article: 1 }

  after_commit :complete_payment, on: :create

  def complete_payment
    payment.complete
  end

  def ensure_total_sufficent
    errors.add(total: 'Wrong token!') unless payment.asset_id == item.asset_id
    errors.add(:total, 'amount not sufficient') unless total >= item.price
  end

  private

  def setup_attributes
    assign_attributes(
      payer: payment.payer,
      receiver: item.author,
      total: payment.amount
    )
  end
end
