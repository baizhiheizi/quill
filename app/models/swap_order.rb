# frozen_string_literal: true

# == Schema Information
#
# Table name: swap_orders
#
#  id                                 :bigint           not null, primary key
#  amount(swapped amount)             :decimal(, )
#  fill(paid amount)                  :decimal(, )
#  min_amount(minimum swapped amount) :decimal(, )
#  raw(raw order response)            :json
#  state                              :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  fill_asset_id(swapped asset)       :uuid
#  pay_asset_id(paid asset)           :uuid
#  payment_id                         :bigint
#  trace_id                           :uuid
#  user_id                            :uuid
#
# Indexes
#
#  index_swap_orders_on_payment_id  (payment_id)
#  index_swap_orders_on_trace_id    (trace_id) UNIQUE
#  index_swap_orders_on_user_id     (user_id)
#
class SwapOrder < ApplicationRecord
  FOX_SWAP_APP_ID = 'a753e0eb-3010-4c4a-a7b2-a7bda4063f62'

  include AASM
  belongs_to :payment
  belongs_to :wallet, class_name: 'MixinNetworkUser', foreign_key: :user_id, primary_key: :uuid, inverse_of: :swap_orders

  validates :trace_id, presence: true
  validates :fill_asset_id, presence: true
  validates :pay_asset_id, presence: true
  validates :min_amount, numericality: { greater_than: 0.000_000_01 }

  after_commit :transfer_to_4swap_async

  delegate :owner, to: :wallet
  delegate :refund!, to: :payment, prefix: true
  delegate :create_refund_transfer!, to: :payment, prefix: true
  delegate :complete!, to: :payment, prefix: true

  aasm column: :state do
    state :paid, initial: true
    state :swapping
    state :rejected
    state :swapped
    state :order_placed
    state :completed
    state :refunded

    event :start do
      transitions from: :paid, to: :swapping
    end

    event :reject, after: :payment_create_refund_transfer! do
      transitions from: :swapping, to: :rejected
    end

    event :swap, guard: :ensure_min_amount_filled, after: :place_payment_order! do
      transitions from: :swapping, to: :swapped
    end

    event :order_place, after: :transfer_change_to_buyer_async do
      transitions from: :swapped, to: :order_placed
    end

    event :complete, after: :payment_complete! do
      transitions from: :order_placed, to: :completed
    end

    event :refund, after: :payment_refund! do
      transitions from: :swapped, to: :refunded
    end
  end

  def transfer_to_4swap_async
    SwapOrderTransferTo4swapWorker.perform_async id
  end

  def transfer_to_4swap!
    r = wallet.mixin_api.create_transfer(
      wallet.pin,
      opponent_id: FOX_SWAP_APP_ID,
      asset_id: pay_asset_id,
      amount: fill.to_f,
      memo: Base64.encode64(
        {
          t: 'swap',
          a: fill_asset_id,
          m: min_amount.to_f.to_s
        }.to_json
      )
    )

    raise r['error'].inspect if r['error'].present?
    return unless r['data']['trace_id'] == trace_id

    start!
  end

  def place_payment_order!
    return if order_placed?

    article = Article.find_by uuid: payment.decrypted_memo['a']
    case payment.decrypted_memo['t']
    when 'BUY'
      article.orders.find_or_create_by!(
        payment: payment,
        order_type: :buy_article
      )
    when 'REWARD'
      article.orders.find_or_create_by!(
        payment: payment,
        order_type: :reward_article
      )
    end
    order_place!
  rescue StandardError => e
    Rails.logger.error e.inspect
    transfer_refund_to_buyer_async
  end

  def transfer_change_to_buyer_aysnc
    SwapOrderTransferChangeToBuyerWorker.perform_async id
  end

  def transfer_change_to_buyer!
    return if completed?

    if (amount - min_amount - 0.000_000_01).positive?
      r = wallet.mixin_api.create_transfer(
        wallet.pin,
        asset_id: fill_asset_id,
        amount: (amount - min_amount).to_f,
        opponent_id: payment.buyer.mixin_uuid,
        trace_id: wallet.mixin_api.unique_conversation_id(trace_id, payment.buyer.mixin_uuid),
        memo: 'CHANGE FROM SWAP'
      )

      raise r['error'].inspect if r['error'].present?
      return unless r['data']['trace_id'] == trace_id
    end

    complete!
  end

  def transfer_refund_to_buyer_async
    SwapOrderTransferRefundToBuyerWorker.perform_async id
  end

  def transfer_refund_to_buyer!
    return if refunded?

    r = wallet.mixin_api.create_transfer(
      wallet.pin,
      asset_id: fill_asset_id,
      amount: amount.to_f,
      opponent_id: payment.buyer.mixin_uuid,
      trace_id: wallet.mixin_api.unique_conversation_id(trace_id, payment.buyer.mixin_uuid),
      memo: 'REFUND FROM SWAP'
    )

    raise r['error'].inspect if r['error'].present?
    return unless r['data']['trace_id'] == trace_id

    refund!
  end

  def ensure_min_amount_filled
    amount > min_amount
  end
end
