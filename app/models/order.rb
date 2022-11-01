# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id         :bigint           not null, primary key
#  citer_type :string
#  item_type  :string
#  order_type :integer
#  state      :string
#  total      :decimal(, )
#  value_btc  :decimal(, )
#  value_usd  :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  buyer_id   :bigint
#  citer_id   :integer
#  item_id    :bigint
#  seller_id  :bigint
#  trace_id   :uuid
#
# Indexes
#
#  index_orders_on_asset_id                 (asset_id)
#  index_orders_on_buyer_id                 (buyer_id)
#  index_orders_on_citer_type_and_citer_id  (citer_type,citer_id)
#  index_orders_on_item_type_and_item_id    (item_type,item_id)
#  index_orders_on_seller_id                (seller_id)
#

class Order < ApplicationRecord
  PLATFORM_RATIO = 0.1

  include AASM
  include Orders::Distributable
  include Orders::Mintable

  belongs_to :buyer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  belongs_to :citer, polymorphic: true, optional: true
  belongs_to :item, polymorphic: true, counter_cache: true
  belongs_to :payment, foreign_key: :trace_id, primary_key: :trace_id, inverse_of: :order
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :orders

  has_many :transfers, as: :source, dependent: :restrict_with_exception
  has_one :collectible, as: :source, dependent: :restrict_with_exception

  before_validation :setup_attributes, on: :create

  # prevent duplicated buy order
  validates :order_type, uniqueness: { scope: %i[order_type buyer_id item_id item_type], if: -> { buy_article? || buy_collection? } }
  validates :total, presence: true
  validates :trace_id, uniqueness: true
  validate :ensure_total_sufficient, on: :create

  enum order_type: { buy_article: 0, reward_article: 1, cite_article: 2, buy_collection: 3 }

  delegate :price_tag, to: :payment, prefix: true

  after_create :subscribe_comments_for_buyer, :broadcast_to_views
  after_create_commit :update_cache_async, :notify_async, :distribute_async

  before_destroy :destroy_notifications

  def broadcast_to_views
    case item
    when Article
      broadcast_to_article_views
    when Collection
      broadcast_to_collection_views
    end
  end

  def broadcast_to_article_views
    I18n.with_locale buyer.locale do
      broadcast_replace_to "user_#{buyer.mixin_uuid}", target: "article_#{item.uuid}_content", partial: 'articles/content', locals: { article: item, user: buyer } if buy_article?

      broadcast_replace_later_to "user_#{buyer.mixin_uuid}", target: "article_#{item.uuid}_buyers", partial: 'articles/buyers', locals: { article: item, user: buyer }
      broadcast_replace_to "user_#{buyer.mixin_uuid}", target: "article_#{item.uuid}_comments_card", partial: 'articles/comments_card', locals: { article: item, user: buyer }
      broadcast_remove_to "user_#{buyer.mixin_uuid}", target: "#{item.uuid}_pre_order_modal"
    end
  end

  def broadcast_to_collection_views
  end

  aasm column: :state do
    state :paid, initial: true
    state :completed
    state :stale

    event :complete, guard: :all_transfers_generated? do
      transitions from: :paid, to: :completed
    end
  end

  def all_transfers_generated?
    transfers
      .where(wallet_id: payment.wallet_id)
      .sum(:amount)
      .round(8) >=
      if payment.wallet_id == QuillBot.api.client_id
        (total * (1 - item.platform_revenue_ratio)).round(8)
      else
        total.round(8)
      end
  end

  def notify
    notify_subscribers
    notify_buyer
  end

  def notify_async
    OrderNotifyWorker.perform_async id
  end

  def notify_subscribers
    if reward_article?
      ArticleRewardedNotification.with(order: self).deliver(buyer.subscribe_by_users)
    elsif buy_article?
      ArticleBoughtNotification.with(order: self).deliver(buyer.subscribe_by_users)
    end
  end

  def notify_buyer
    OrderCreatedNotification.with(order: self).deliver(buyer) if order_type.in? %w[buy_article reward_article buy_collection]
  end

  def subscribe_comments_for_buyer
    buyer.create_action :commenting_subscribe, target: article
  end

  def article
    item if item.is_a? Article
  end

  def update_cache_async
    OrderUpdateCacheWorker.perform_async id
  end

  def update_cache
    item.update_revenue if item.is_a?(Article)
  end

  def notifications
    @notifications = Notification.where(params: { order: self })
  end

  def destroy_notifications
    notifications.destroy_all
  end

  def cache_history_ticker
    r = QuillBot.api.ticker asset_id, created_at.utc.rfc3339
    update value_btc: r['price_btc'].to_f * total, value_usd: r['price_usd'].to_f * total
  end

  def cache_history_ticker_async
    CacheOrderHistoryTickerWorker.perform_async id
  end

  def price_tag
    [format('%.8f', total), currency&.symbol].join(' ')
  end

  private

  def setup_attributes
    amount =
      if payment.asset_id == item.asset_id || cite_article?
        payment.amount.round(8)
      elsif payment.swap_order&.swapped? || payment.swap_order&.completed?
        if buy_article? || buy_collection?
          payment.swap_order.min_amount
        elsif reward_article?
          payment.swap_order.amount
        end
      end

    self.currency = if cite_article?
                      payment.currency
                    else
                      item.currency
                    end
    assign_attributes(
      buyer: payment.payer,
      seller: item.author,
      total: amount,
      value_btc: currency.price_btc.to_f * amount,
      value_usd: currency.price_usd.to_f * amount
    )
  end

  def ensure_total_sufficient
    errors.add(:total, 'insufficient') if (buy_article? || buy_collection?) && total.floor(8) < item.price.floor(8)
  end
end
