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

  after_create :generate_order!
  after_create_commit do
    notify_payer
  end

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

  def decoded_memo
    # memo from Quill user
    # memo = {
    #  't': BUY|REWARD|CITE|REVENUE,
    #  'a': article's uuid,
    #  'c': citer's uuid,
    #  'p': pre order trace ID
    #  'l': collection's uuid
    # }
    #
    @decoded_memo =
      begin
        JSON.parse Base64.decode64(memo.to_s)
      rescue JSON::ParserError
        {}
      end
  end

  def memo_correct?
    decoded_memo.key?('t') &&
      decoded_memo['t'].in?(%w[BUY REWARD CITE REVENUE]) &&
      (decoded_memo.key?('a') || decoded_memo.key?('l'))
  end

  def article
    return if decoded_memo['a'].blank?

    @article ||= Article.find_by uuid: decoded_memo['a']
  end

  def collection
    return if decoded_memo['l'].blank?

    @collection ||= Collection.find_by uuid: decoded_memo['l']
  end

  def citer
    return unless decoded_memo['t'] == 'CITE'

    @citer ||= Article.find_by(uuid: decoded_memo['c'])
  end

  def pre_order
    return if decoded_memo['f'].blank?

    @pre_order ||= PreOrder.find_by follow_id: decoded_memo['f']
  end

  def generate_order!
    return unless memo_correct?

    if article.present?
      generate_article_order!
    elsif collection.present?
      generate_collection_order!
    end

    pre_order&.pay! if pre_order&.may_pay?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error e
    reload.generate_refund_transfer!
  end

  def generate_article_order!
    return if article.blank?

    raise ActiveRecord::RecordInvalid, 'blocked by author' if article.author.block_user?(payer)

    if decoded_memo['t'] == 'REVENUE'
      complete!
    elsif asset_id == article.asset_id || decoded_memo['t'] == 'CITE'
      place_article_order!
    elsif swappable?
      place_swap_order!
    else
      generate_refund_transfer!
    end
  end

  def generate_collection_order!
    return if collection.blank?

    raise ActiveRecord::RecordInvalid, 'blocked by author' if collection.author.block_user?(payer)

    if asset_id == collection.asset_id
      place_collection_order!
    elsif swappable?
      place_swap_order!
    else
      generate_refund_transfer!
    end
  end

  def place_swap_order!
    if article.present?
      create_swap_order!(
        funds: amount,
        min_amount: decoded_memo['t'] == 'BUY' ? article.price : nil,
        fill_asset_id: article.asset_id,
        pay_asset_id: asset_id,
        trace_id: QuillBot.api.unique_conversation_id(wallet_id, trace_id),
        user_id: wallet_id
      )
    elsif collection.present?
      create_swap_order!(
        funds: amount,
        min_amount: collection.price,
        fill_asset_id: collection.asset_id,
        pay_asset_id: asset_id,
        trace_id: QuillBot.api.unique_conversation_id(wallet_id, trace_id),
        user_id: wallet_id
      )
    end
  end

  def place_article_order!
    case decoded_memo['t']
    when 'BUY'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :buy_article
      )
      complete!
    when 'REWARD'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :reward_article
      )
      complete!
    when 'CITE'
      article.orders.find_or_create_by!(
        payment: self,
        order_type: :cite_article,
        citer: citer
      )
      complete!
    when 'REVENUE'
      complete!
    else
      generate_refund_transfer!
    end
  end

  def place_collection_order!
    case decoded_memo['t']
    when 'BUY'
      collection.orders.find_or_create_by!(
        payment: self,
        order_type: :buy_collection
      )
      complete!
    else
      generate_refund_transfer!
    end
  end

  def generate_refund_transfer!
    return if order&.id.present?
    return if refund_transfer.present?

    create_refund_transfer!(
      wallet_id: wallet_id,
      transfer_type: :payment_refund,
      opponent_id: opponent_id,
      amount: amount,
      asset_id: asset_id,
      trace_id: QuillBot.api.unique_conversation_id(trace_id, opponent_id),
      memo: 'REDUND'
    )
  end

  def wallet_id
    @wallet_id = snapshot&.user_id
  end

  def ensure_refund_transfer_created
    refund_transfer.present? || swap_order&.refunded?
  end

  def notify_payer
    PaymentCreatedNotification.with(payment: self).deliver(payer) if decoded_memo['t'].in? %w[BUY REWARD]
  end

  def price_tag
    [format('%.8f', amount), currency&.symbol].join(' ')
  end

  def snapshot_url
    [
      'https://mixin.one/snapshots/',
      snapshot_id
    ].join
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
      if decoded_memo['t'] == 'CITE'
        Article.find_by(uuid: decoded_memo['c']).author
      elsif pre_order.present?
        pre_order.payer
      else
        User.find_by mixin_uuid: opponent_id
      end
  end
end
