# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id         :bigint           not null, primary key
#  item_type  :string
#  order_type :integer
#  state      :string
#  total      :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  buyer_id   :bigint
#  item_id    :bigint
#  seller_id  :bigint
#  trace_id   :uuid
#
# Indexes
#
#  index_orders_on_buyer_id               (buyer_id)
#  index_orders_on_item_type_and_item_id  (item_type,item_id)
#  index_orders_on_seller_id              (seller_id)
#
class Order < ApplicationRecord
  AUTHOR_RATIO = 0.5
  READER_RATIO = 0.4
  PRSDIGG_RATIO = 0.1
  MINIMUM_AMOUNT = 0.0000_0001

  include AASM

  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  belongs_to :item, polymorphic: true, counter_cache: true

  has_many :transfers, as: :source, dependent: :nullify
  has_one :payment, foreign_key: :trace_id, primary_key: :trace_id, dependent: :nullify, inverse_of: :order

  before_validation :setup_attributes

  # prevent duplicated buy order
  validates :order_type, uniqueness: { scope: %i[order_type buyer_id item_id item_type], if: -> { buy_article? } }
  validates :total, presence: true
  validate :ensure_total_sufficient

  enum order_type: { buy_article: 0, reward_article: 1 }

  after_commit :complete_payment, :create_revenue_transfers_async, \
               :update_item_revenue, :notify_subscribers_async, \
               :notify_buyer,
               on: :create

  aasm column: :state do
    state :paid, initial: true
    state :completed

    event :complete, guard: :all_transfers_processed? do
      transitions from: :paid, to: :completed
    end
  end

  def create_revenue_transfers_async
    CreateOrderRevenueTransfersWorker.perform_async trace_id
  end

  # transfer revenue to author and readers
  def create_revenue_transfers
    # the share for invested readers before
    amount = total * READER_RATIO

    # payment maybe swapped
    revenue_asset_id = payment.swap_order&.fill_asset_id || payment.asset_id

    # the present orders
    _orders =
      item.orders
          .where('id < ? and created_at < ?', id, created_at)

    # total investment
    sum = _orders.sum(:total)

    # create reader transfer
    _distributed_amount = 0
    _orders.each do |_order|
      # ignore if amount is less than minium amout for Mixin Network
      _amount = (amount * _order.total / sum).round(8)
      next if (_amount - MINIMUM_AMOUNT).negative?

      transfers.create_with(
        wallet: payment.wallet,
        transfer_type: :reader_revenue,
        opponent_id: _order.buyer.mixin_uuid,
        asset_id: revenue_asset_id,
        amount: _amount.to_f.to_s,
        memo: "读者收益来自文章《#{item.title}》".truncate(140)
      ).find_or_create_by!(
        trace_id: PrsdiggBot.api.unique_conversation_id(trace_id, _order.trace_id)
      )

      _distributed_amount += _amount
    end

    # create prsdigg transfer
    _prsdigg_amount = (total * PRSDIGG_RATIO).round(8)
    if payment.wallet.present?
      transfers.create_with(
        wallet: payment.wallet,
        transfer_type: :prsdigg_revenue,
        opponent_id: PrsdiggBot.api.client_id,
        asset_id: revenue_asset_id,
        amount: _prsdigg_amount.to_f.to_s,
        memo: "article uuid: #{item.uuid}》".truncate(140)
      ).find_or_create_by!(
        trace_id: payment.wallet.mixin_api.unique_conversation_id(trace_id, PrsdiggBot.api.client_id)
      )
    end

    # create author transfer
    transfers.create_with(
      wallet: payment.wallet,
      transfer_type: :author_revenue,
      opponent_id: item.author.mixin_uuid,
      asset_id: revenue_asset_id,
      amount: (total - _distributed_amount - _prsdigg_amount).round(8),
      memo: "#{payment.payer.name} #{buy_article? ? '购买' : '赞赏'}了你的文章《#{item.title}》".truncate(140)
    ).find_or_create_by!(
      trace_id: PrsdiggBot.api.unique_conversation_id(trace_id, item.author.mixin_uuid)
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
    errors.add(:total, 'Insufficient amount!') if buy_article? && total < item.price
  end

  def subscribers
    @subscribers = buyer.reading_subscribe_by_users
  end

  def notify_subscribers_async
    return if reward_article?

    messages = subscribers.pluck(:mixin_uuid).map do |_uuid|
      PrsdiggBot.api.app_card(
        conversation_id: PrsdiggBot.api.unique_conversation_id(_uuid),
        recipient_id: _uuid,
        data: {
          icon_url: 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256',
          title: item.title.truncate(36),
          description: format('%<buyer_name>s 买了新文章', buyer_name: buyer.name),
          action: format('%<host>s/articles/%<uuid>s', host: Rails.application.credentials.fetch(:host), uuid: item.uuid)
        }
      )
    end

    messages.each do |message|
      SendMixinMessageWorker.perform_async message
    end
  end

  def notify_buyer
    TextNotificationService.new.call(
      "成功支付#{total} PRS #{buy_article? ? '购买' : '赞赏'}文章《#{item.title}》",
      recipient_id: buyer.mixin_uuid
    )
  end

  def article
    item if item.is_a? Article
  end

  private

  def setup_attributes
    amount =
      if payment.asset_id == Article::PRS_ASSET_ID
        payment.amount
      elsif payment.swap_order&.swapped? || payment.swap_order&.completed?
        if buy_article?
          payment.swap_order.min_amount
        elsif reward_article?
          payment.swap_order.amount
        end
      end

    assign_attributes(
      buyer: payment.payer,
      seller: item.author,
      total: amount
    )
  end
end
