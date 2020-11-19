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
  include AASM

  belongs_to :payer, class_name: 'User', foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :payments
  belongs_to :mixin_network_snapshot, foreign_key: :trace_id, primary_key: :trace_id, optional: true, inverse_of: false

  has_one :transfer, as: :source, dependent: :nullify
  has_one :order, primary_key: :trace_id, foreign_key: :trace_id, dependent: :nullify, inverse_of: :payment

  before_validation :setup_attributes

  validates :amount, presence: true
  validates :raw, presence: true
  validates :asset_id, presence: true
  validates :opponent_id, presence: true
  validates :snapshot_id, presence: true, uniqueness: true
  validates :trace_id, presence: true, uniqueness: true

  after_create :create_order!

  aasm column: :state do
    state :paid, initial: true
    state :completed
    state :refunded

    event :complete do
      transitions from: :paid, to: :completed
    end

    event :refund do
      transitions from: :paid, to: :refunded
    end
  end

  def create_order!
    # memo = {
    #  t: BUY|REWARD,
    #  a: article's uuid,
    # }
    decpreted_memo =
      begin
        JSON.parse Base64.decode64(memo.to_s)
      rescue JSON::ParserError
        {}
      end

    ActiveRecord::Base.transaction do
      article = Article.find_by!(uuid: decpreted_memo['a'])

      case decpreted_memo['t']
      when 'BUY'
        article.orders
               .create_with(
                 payment: self
               )
               .find_or_create_by!(
                 buyer: payer,
                 order_type: :buy_article
               )
      when 'REWARD'
        article.orders.find_or_create_by!(
          payment: self,
          order_type: :reward_article
        )
      else
        refund
      end
    end
  rescue StandardError => e
    Rails.logger.error e.inspect
    refund
  end

  def refund
    return if order.present?

    create_transfer!(
      transfer_type: :payment_refund,
      opponent_id: opponent_id,
      amount: amount,
      asset_id: asset_id,
      trace_id: MixinBot.api.unique_conversation_id(trace_id, opponent_id),
      memo: 'REDUND'
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
