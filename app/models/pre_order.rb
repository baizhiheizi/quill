# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_orders
#
#  id         :bigint           not null, primary key
#  amount     :decimal(, )
#  item_type  :string
#  memo       :string
#  order_type :string
#  state      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  follow_id  :uuid
#  item_id    :bigint
#  payee_id   :uuid
#  payer_id   :uuid
#  trace_id   :uuid
#
# Indexes
#
#  index_pre_orders_on_item      (item_type,item_id)
#  index_pre_orders_on_payee_id  (payee_id)
#  index_pre_orders_on_payer_id  (payer_id)
#
class PreOrder < ApplicationRecord
  extend Enumerize
  include AASM

  enumerize :order_type, in: %i[buy_article reward_article]

  belongs_to :item, polymorphic: true
  belongs_to :payer, class_name: 'User', primary_key: :mixin_uuid
  belongs_to :payee, class_name: 'MixinNetworkUser', primary_key: :uuid
  belongs_to :currency, class_name: 'Currency', primary_key: :asset_id, foreign_key: :asset_id, inverse_of: false

  before_validation :setup_attributes, on: :create

  validates :trace_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :memo, presence: true
  validate :ensure_payer_not_author

  aasm column: :state do
    state :drafted, initial: true
    state :paid

    event :pay, after_commit: :broadcast_to_views do
      transitions from: :drafted, to: :paid
    end
  end

  def amount_tag
    "#{format('%.8f', amount).gsub(/0+\z/, '0')} #{currency.symbol}"
  end

  def pay_amount(pay_asset_id = nil)
    @pay_amount ||=
      case pay_asset_id
      when asset_id
        amount
      else
        begin
          Foxswap.api.pre_order(
            pay_asset_id: pay_asset_id,
            fill_asset_id: asset_id,
            amount: (amount * 1.01).round(8).to_r.to_f
          )['data']['funds']
        rescue StandardError
          nil
        end
      end
  end

  def broadcast_to_views
    broadcast_update_to "user_#{payer_id}", target: "#{type.underscore}_#{id}_state", partial: 'pre_orders/state', locals: { pre_order: self }
  end

  def to_param
    follow_id
  end

  private

  def setup_attributes
    self.trace_id = item.payment_trace_id payer
    self.follow_id = SecureRandom.uuid
    self.memo =
      case order_type
      when 'buy_article'
        Base64.urlsafe_encode64({ t: 'BUY', a: item.uuid, f: follow_id }.to_json)
      when 'reward_article'
        Base64.urlsafe_encode64({ t: 'REWARD', a: item.uuid, f: follow_id }.to_json)
      end
    self.payee_id = payer.wallet_id || item.wallet_id || QuillBot.api.client_id
    self.asset_id = item.asset_id if asset_id.blank?
  end

  def ensure_payer_not_author
    errors.add(:payer, 'cannot be author') if payer == item.author
  end
end
