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
  FOX_SWAP_APP_ID = 'a753e0eb-3010-4c4a-a7b2-a7bda4063f62'
  FOX_SWAP_BROKER_ID = 'd8d186c4-62a7-320b-b930-11dfc1c76708'

  include TokenSupportable
  include AASM
  belongs_to :payment
  belongs_to :wallet, class_name: 'MixinNetworkUser', foreign_key: :user_id, primary_key: :uuid, inverse_of: :swap_orders

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
  rescue StandardError => e
    Rails.logger.error e.inspect
    create_refund_transfer!
  end

  def create_change_transfer!
    return if completed?
    return if amount.blank?
    return if min_amount.blank? || (amount - min_amount - 0.000_000_01).negative?

    _trace_id = wallet.mixin_api.unique_conversation_id(trace_id, payment.payer.mixin_uuid)
    transfers.create_with(
      wallet: wallet,
      transfer_type: :swap_change,
      opponent_id: payment.payer.mixin_uuid,
      asset_id: fill_asset_id,
      amount: (amount - min_amount).to_f,
      memo: 'CHANGE FROM SWAP'
    ).find_or_create_by!(
      trace_id: _trace_id
    )
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
    amount.to_f > min_amount.to_f
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

  def pay_asset
    SUPPORTED_TOKENS.find(&->(token) { token[:asset_id] == pay_asset_id })
  end

  def fill_asset
    SUPPORTED_TOKENS.find(&->(token) { token[:asset_id] == fill_asset_id })
  end
end
