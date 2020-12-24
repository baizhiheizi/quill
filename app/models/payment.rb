# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id          :bigint           not null, primary key
#  amount      :decimal(, )
#  memo        :string
#  raw         :json
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  asset_id    :uuid
#  opponent_id :uuid
#  snapshot_id :uuid
#  trace_id    :uuid
#
# Indexes
#
#  index_payments_on_trace_id  (trace_id) UNIQUE
#
class Payment < ApplicationRecord
  FOXSWAP_DISABLE = true

  include TokenSupportable
  include AASM

  belongs_to :payer, class_name: 'User', foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :payments
  belongs_to :snapshot, class_name: 'MixinNetworkSnapshot', foreign_key: :trace_id, primary_key: :trace_id, optional: true, inverse_of: false

  has_one :refund_transfer, -> { where(transfer_type: :payment_refund) }, class_name: 'Transfer', as: :source, dependent: :nullify, inverse_of: false
  has_one :order, primary_key: :trace_id, foreign_key: :trace_id, dependent: :nullify, inverse_of: :payment
  has_one :swap_order, dependent: :nullify

  before_validation :setup_attributes

  validates :amount, presence: true
  validates :raw, presence: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true
  validates :snapshot_id, presence: true, uniqueness: true

  validates :trace_id, presence: true, uniqueness: true

  after_commit :place_order!, :notify_payer, on: :create

  aasm column: :state do
    state :paid, initial: true
    state :completed
    state :refunded

    event :complete do
      transitions from: :paid, to: :completed
    end

    event :refund, guard: :ensure_refund_transfer_created do
      transitions from: :paid, to: :refunded
    end
  end

  def decrypted_memo
    # memo from PRSDigg user
    # memo = {
    #  t: BUY|REWARD,
    #  a: article's uuid,
    #  p: price as PRS
    # }
    #
    @decrypted_memo =
      begin
        JSON.parse Base64.decode64(memo.to_s)
      rescue JSON::ParserError
        {}
      end
  end

  def place_order!
    return unless decrypted_memo['t'].in? %w[BUY REWARD]

    if asset_id == Article::PRS_ASSET_ID
      place_article_order!
    elsif FOXSWAP_DISABLE
      generate_refund_transfer!
    else
      place_swap_order!
    end
  end

  def place_swap_order!
    create_swap_order!(
      funds: amount,
      min_amount: decrypted_memo['p'],
      fill_asset_id: Article::PRS_ASSET_ID,
      pay_asset_id: asset_id,
      trace_id: PrsdiggBot.api.unique_conversation_id(wallet.uuid, trace_id),
      wallet: wallet
    )
  rescue StandardError => e
    Rails.logger.error e.inspect
    reload.generate_refund_transfer!
  end

  def place_article_order!
    article = Article.find_by!(uuid: decrypted_memo['a'])

    case decrypted_memo['t']
    when 'BUY'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :buy_article
      )
    when 'REWARD'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :reward_article
      )
    else
      generate_refund_transfer!
    end
  rescue StandardError => e
    Rails.logger.error e.inspect
    reload.generate_refund_transfer!
  end

  def generate_refund_transfer!
    return if order&.id.present?
    return if refund_transfer.present?

    create_refund_transfer!(
      wallet: wallet,
      transfer_type: :payment_refund,
      opponent_id: opponent_id,
      amount: amount,
      asset_id: asset_id,
      trace_id: PrsdiggBot.api.unique_conversation_id(trace_id, opponent_id),
      memo: 'REDUND'
    )
  end

  def wallet
    @wallet = snapshot&.wallet
  end

  def ensure_refund_transfer_created
    refund_transfer.present? || swap_order&.refunded?
  end

  def notify_payer
    TransferNotificationService.new.call(
      recipient_id: payer.mixin_uuid,
      asset_id: asset_id,
      amount: -amount,
      trace_id: trace_id
    )
  end

  private

  def setup_attributes
    assign_attributes(
      amount: raw['amount'].to_f,
      memo: raw['memo'] || raw['data'],
      asset_id: raw['asset_id'] || raw['asset']['asset_id'],
      opponent_id: raw['opponent_id'],
      snapshot_id: raw['snapshot_id'],
      trace_id: raw['trace_id']
    )
  end
end
