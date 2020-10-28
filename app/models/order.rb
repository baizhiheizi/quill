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
  AUTHOR_RATIO = 0.5
  READER_RATIO = 0.4
  PRSDIGG_RATIO = 0.1
  MINIMUM_AMOUNT = 0.0000_0001

  include AASM

  belongs_to :payer, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :item, polymorphic: true, counter_cache: true

  has_many :transfers, as: :source, dependent: :nullify
  has_one :payment, foreign_key: :trace_id, primary_key: :trace_id, dependent: :nullify, inverse_of: :order

  before_validation :setup_attributes

  validate :ensure_total_sufficient

  enum order_type: { buy_article: 0, reward_article: 1 }

  after_commit :complete_payment, :create_revenue_transfers_async, :update_item_revenue, on: :create

  aasm column: :state do
    state :paid, initial: true
    state :complete

    event :complete, guard: :all_transfers_processed? do
      transitions from: :paid, to: :complete
    end
  end

  def create_revenue_transfers_async
    CreateOrderRevenueTransfersWorker.perform_async trace_id
  end

  # transfer revenue to author and readers
  def create_revenue_transfers
    # the share for invested readers before
    amount = total * READER_RATIO

    # the present orders
    _orders =
      item.orders
          .where(id: ...id, created_at: ...created_at)
          .where.not(id: id)

    # total investment
    sum = _orders.sum(:total)

    # create reader transfer
    _orders.each do |_order|
      # ignore if amount is less than minium amout for Mixin Network
      _amount = (amount * _order.total / sum).round(8)
      next if (_amount - MINIMUM_AMOUNT).negative?

      transfers.create_with(
        transfer_type: :reader_revenue,
        opponent_id: _order.payer.mixin_uuid,
        asset_id: payment.asset_id,
        amount: _amount.to_f.to_s,
        memo: "读者收益来自文章《#{item.title}》".truncate(140)
      ).find_or_create_by!(
        trace_id: MixinBot.api.unique_conversation_id(_order.trace_id, trace_id)
      )
    end

    # create author transfer
    transfers.create_with(
      transfer_type: :author_revenue,
      opponent_id: item.author.mixin_uuid,
      asset_id: payment.asset_id,
      amount: (total * (1 - PRSDIGG_RATIO) - amount).round(8),
      memo: "作者收益来自文章《#{item.title}》".truncate(140)
    ).find_or_create_by!(
      trace_id: MixinBot.api.unique_conversation_id(trace_id, item.author.mixin_uuid)
    )
  end

  def all_transfers_processed?
    transfers.unprocessed.blank?
  end

  def complete_payment
    payment.complete! if payment.paid?
  end

  def update_item_revenue
    item.update_revenue
  end

  def ensure_total_sufficient
    errors.add(total: 'Wrong token!') unless payment.asset_id == item.asset_id
    errors.add(:total, 'Insufficient amount!') unless total >= item.price
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
