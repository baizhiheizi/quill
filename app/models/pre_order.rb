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
  include PreOrders::Swappable

  enumerize :order_type, in: %i[buy_article reward_article buy_collection mint_collection]

  belongs_to :item, polymorphic: true
  belongs_to :payer, class_name: 'User', primary_key: :mixin_uuid
  belongs_to :payee, class_name: 'MixinNetworkUser', primary_key: :uuid, optional: true
  belongs_to :currency, class_name: 'Currency', primary_key: :asset_id, foreign_key: :asset_id, inverse_of: false

  before_validation :setup_attributes, on: :create

  validates :trace_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :memo, presence: true
  validate :ensure_payer_not_author

  aasm column: :state do
    state :drafted, initial: true
    state :paid
    state :expired

    event :pay, after_commit: :broadcast_to_views do
      transitions from: :drafted, to: :paid
    end

    event :expire do
      transitions from: :drafted, to: :expired
    end
  end

  def amount_tag
    "#{format('%.8f', amount).gsub(/0+\z/, '0')} #{currency.symbol}"
  end

  def mixpay_supported?
    return false unless asset_id.in?(Mixpay.api.settlement_asset_ids)

    Mixpay.api.quote_assets_cached.find(&->(asset) { asset['assetId'] == asset_id && amount >= asset['minQuoteAmount'].to_f && amount <= asset['maxQuoteAmount'].to_f }).present?
  end

  def broadcast_to_views
    I18n.with_locale payer.locale do
      broadcast_update_to(
        "user_#{payer_id}",
        target: "#{type.underscore}_#{id}_state",
        html: ApplicationController.render(
          PreOrders::StateComponent.new(pre_order: self)
        )
      )
    end
  end

  def to_param
    follow_id
  end

  def decoded_memo
    JSON.parse Base64.decode64(memo)
  end

  private

  def setup_attributes
    self.follow_id = SecureRandom.uuid
    self.trace_id =
      case order_type
      when 'reward_article'
        SecureRandom.uuid
      when 'buy_article', 'buy_collection', 'mint_collection'
        item.payment_trace_id payer
      end
    self.memo =
      case order_type
      when 'buy_article'
        Base64.urlsafe_encode64({ t: 'BUY', a: item.uuid, f: follow_id }.to_json, padding: false)
      when 'reward_article'
        Base64.urlsafe_encode64({ t: 'REWARD', a: item.uuid, f: follow_id }.to_json, padding: false)
      when 'buy_collection'
        Base64.urlsafe_encode64({ t: 'BUY', l: item.uuid, f: follow_id }.to_json, padding: false)
      when 'mint_collection'
        Base64.urlsafe_encode64({ t: 'MINT', l: item.uuid, f: follow_id }.to_json, padding: false)
      end

    self.payee_id = QuillBot.api.client_id

    self.asset_id = item.asset_id if asset_id.blank?
  end

  def ensure_payer_not_author
    errors.add(:payer, 'cannot be author') if payer == item.author
  end
end
