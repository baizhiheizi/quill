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
#  payer_id    :uuid
#  snapshot_id :uuid
#  trace_id    :uuid
#
# Indexes
#
#  index_payments_on_asset_id     (asset_id)
#  index_payments_on_opponent_id  (opponent_id)
#  index_payments_on_payer_id     (payer_id)
#  index_payments_on_trace_id     (trace_id) UNIQUE
#
class Payment < ApplicationRecord
  include AASM

  belongs_to :payer, class_name: 'User', primary_key: :mixin_uuid, inverse_of: :payments, optional: true
  belongs_to :payer_wallet, class_name: 'MixinNetworkUser', foreign_key: :opponent_id, primary_key: :uuid, inverse_of: false, optional: true
  belongs_to :snapshot, -> { where(amount: 0...) }, class_name: 'MixinNetworkSnapshot', foreign_key: :trace_id, primary_key: :trace_id, optional: true, inverse_of: false
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :payments, optional: true

  has_one :refund_transfer, -> { where(transfer_type: :payment_refund) }, class_name: 'Transfer', as: :source, dependent: :nullify, inverse_of: false
  has_one :order, primary_key: :trace_id, foreign_key: :trace_id, dependent: :restrict_with_exception, inverse_of: :payment
  has_one :swap_order, dependent: :nullify

  before_validation :setup_attributes, on: :create

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :raw, presence: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true
  validates :snapshot_id, presence: true, uniqueness: true
  validates :trace_id, presence: true, uniqueness: true

  after_commit :place_order!, :notify_payer, on: :create

  delegate :swappable?, to: :currency

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
    #  't': BUY|REWARD|CITE|REVENUE,
    #  'a': article's uuid,
    #  'c': citer's uuid
    # }
    #
    @decrypted_memo =
      begin
        JSON.parse Base64.decode64(memo.to_s)
      rescue JSON::ParserError
        {}
      end
  end

  def memo_correct?
    decrypted_memo.key?('a') && decrypted_memo.key?('t') && decrypted_memo['t'].in?(%w[BUY REWARD CITE REVENUE])
  end

  def article
    @article = Article.find_by! uuid: decrypted_memo['a']
  end

  def citer
    return unless decrypted_memo['t'] == 'CITE'

    @citer = Article.find_by(uuid: decrypted_memo['c'])
  end

  def place_order!
    return unless memo_correct?

    if asset_id == article.asset_id
      place_article_order!
    elsif swappable?
      place_swap_order!
    else
      generate_refund_transfer!
    end
  rescue RuntimeError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    reload.generate_refund_transfer!
    raise e if Rails.env.development?
  end

  def place_swap_order!
    create_swap_order!(
      funds: amount,
      min_amount: decrypted_memo['t'] == 'BUY' ? article.price : nil,
      fill_asset_id: article.asset_id,
      pay_asset_id: asset_id,
      trace_id: PrsdiggBot.api.unique_conversation_id(wallet.uuid, trace_id),
      wallet: wallet
    )
  rescue ActiveRecord::RecordInvalid => e
    reload.generate_refund_transfer!
    raise e if Rails.env.development?
  end

  def place_article_order!
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
    when 'CITE'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :cite_article,
        citer: citer
      )
    when 'REVENUE'
      complete!
    else
      generate_refund_transfer!
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    reload.generate_refund_transfer!
    raise e if Rails.env.development?
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
    PaymentCreatedNotification.with(payment: self).deliver(payer) if decrypted_memo['t'].in? %w[BUY REWARD]
  end

  def price_tag
    [format('%.8f', amount), currency&.symbol].join(' ')
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
    self.payer =
      if decrypted_memo['t'] == 'CITE'
        Article.find_by(uuid: decrypted_memo['c']).author
      else
        User.find_by mixin_uuid: opponent_id
      end
  end
end
