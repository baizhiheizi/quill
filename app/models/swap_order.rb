# frozen_string_literal: true

# == Schema Information
#
# Table name: swap_orders
#
#  id                                 :bigint           not null, primary key
#  amount(swapped amount)             :decimal(, )
#  funds(paid amount)                 :decimal(, )
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
  SUPPORTED_ASSETS = [
    Currency::PRS_ASSET_ID,
    Currency::BTC_ASSET_ID,
    Currency::ETH_ASSET_ID,
    Currency::EOS_ASSET_ID,
    Currency::MOB_ASSET_ID,
    Currency::BOX_ASSET_ID,
    Currency::USDT_ASSET_ID,
    Currency::PUSD_ASSET_ID,
    Currency::XIN_ASSET_ID
  ].freeze
  FOXSWAP_ENABLE = true
  FOX_SWAP_APP_ID = 'a753e0eb-3010-4c4a-a7b2-a7bda4063f62'
  FOX_SWAP_BROKER_ID = 'd8d186c4-62a7-320b-b930-11dfc1c76708'

  include AASM
  belongs_to :payment
  belongs_to :wallet, class_name: 'MixinNetworkUser', foreign_key: :user_id, primary_key: :uuid, inverse_of: :swap_orders
  belongs_to :pay_asset, class_name: 'Currency', primary_key: :asset_id
  belongs_to :fill_asset, class_name: 'Currency', primary_key: :asset_id

  has_many :transfers, as: :source, dependent: :nullify

  validates :trace_id, presence: true
  validates :fill_asset_id, presence: true
  validates :pay_asset_id, presence: true

  after_create :create_fox_swap_transfer!

  delegate :owner, to: :wallet
  delegate :payer, to: :payment
  delegate :generate_refund_transfer!, to: :payment, prefix: true

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

    event :reject, after_commit: %i[payment_generate_refund_transfer! notify_payer sync_order] do
      transitions from: :swapping, to: :rejected
    end

    event :swap, guard: :ensure_min_amount_filled, after_commit: :place_payment_order! do
      transitions from: :swapping, to: :swapped
    end

    event :order_place, after_commit: :create_change_transfer! do
      transitions from: :swapped, to: :order_placed
    end

    event :complete, after_commit: %i[payment_complete! notify_payer sync_order] do
      transitions from: :order_placed, to: :completed
    end

    event :refund, after_commit: %i[payment_refund! notify_payer sync_order] do
      transitions from: :swapped, to: :refunded
    end
  end

  def create_fox_swap_transfer!
    transfers.create_with(
      wallet: wallet,
      transfer_type: :fox_swap,
      queue_priority: :critical,
      opponent_id: FOX_SWAP_BROKER_ID,
      asset_id: pay_asset_id,
      amount: funds.to_f,
      memo: Base64.encode64(
        {
          t: 'swap',
          a: fill_asset_id,
          m: min_amount.present? ? min_amount.to_f.to_s : nil
        }.to_json
      )
    ).find_or_create_by!(
      trace_id: trace_id
    )
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
  rescue ActiveRecord::RecordInvalid => e
    create_refund_transfer!
    raise e if Rails.env.development?
  end

  def create_change_transfer!
    return if completed?
    return if amount.blank?

    _amount = (amount - min_amount.to_f).to_f
    if min_amount.blank? || (_amount - Transfer::MINIMUM_AMOUNT).negative?
      complete!
    else
      _trace_id = wallet.mixin_api.unique_conversation_id(trace_id, payment.payer.mixin_uuid)
      transfers.create_with(
        wallet: wallet,
        transfer_type: :swap_change,
        opponent_id: payment.payer.mixin_uuid,
        asset_id: fill_asset_id,
        amount: _amount,
        memo: 'CHANGE FROM SWAP'
      ).find_or_create_by!(
        trace_id: _trace_id
      )
    end
  end

  def create_refund_transfer!
    return if refunded?

    _trace_id = wallet.mixin_api.unique_conversation_id(trace_id, payment.payer.mixin_uuid)
    transfers.create_with(
      wallet: wallet,
      transfer_type: :swap_refund,
      opponent_id: payment.payer.mixin_uuid,
      asset_id: fill_asset_id,
      amount: amount.to_f,
      memo: 'REFUND FROM SWAP'
    ).find_or_create_by!(
      trace_id: _trace_id
    )
  end

  def ensure_min_amount_filled
    amount.to_f >= min_amount.to_f
  end

  def article
    @article = owner.is_a?(Article) && owner
  end

  def payment_complete!
    payment.complete! if payment.paid?
  end

  def payment_refund!
    payment.refund! if payment.paid?
  end

  def sync_order
    r = Foxswap.api.order(trace_id, authorization: wallet.mixin_api.access_token('GET', '/me'))
    update raw: r['data']
  end

  def notify_payer
    return unless state.in? %w[completed refunded rejected]

    SwapOrderFinishedNotification.with(swap_order: self).deliver(payer)
  end
end
