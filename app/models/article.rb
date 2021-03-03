# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                                  :bigint           not null, primary key
#  commenting_subscribers_count        :integer          default(0)
#  comments_count                      :integer          default(0), not null
#  content                             :text
#  downvotes_count                     :integer          default(0)
#  intro                               :string
#  orders_count                        :integer          default(0), not null
#  price                               :decimal(, )      not null
#  revenue                             :decimal(, )      default(0.0)
#  source                              :string
#  state                               :string
#  tags_count                          :integer          default(0)
#  title                               :string
#  upvotes_count                       :integer          default(0)
#  uuid                                :uuid
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  asset_id(asset_id in Mixin Network) :uuid
#  author_id                           :bigint
#
# Indexes
#
#  index_articles_on_asset_id   (asset_id)
#  index_articles_on_author_id  (author_id)
#  index_articles_on_uuid       (uuid) UNIQUE
#
class Article < ApplicationRecord
  SUPPORTED_ASSETS = [Currency::PRS_ASSET_ID, Currency::BTC_ASSET_ID].freeze
  MINIMUM_PRICE_PRS = 1
  MINIMUM_PRICE_BTC = 0.000_001

  include AASM

  belongs_to :author, class_name: 'User', inverse_of: :articles
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :articles

  has_many :orders, as: :item, dependent: :nullify
  has_many :buy_orders, -> { where(order_type: :buy_article) }, class_name: 'Order', as: :item, dependent: :nullify, inverse_of: false
  has_many :reward_orders, -> { where(order_type: :reward_article) }, class_name: 'Order', as: :item, dependent: :nullify, inverse_of: false

  has_many :readers, -> { distinct }, through: :orders, source: :buyer
  has_many :buyers, -> { distinct }, through: :buy_orders, source: :buyer
  has_many :rewarders, -> { distinct }, through: :reward_orders, source: :buyer

  has_many :transfers, through: :orders, dependent: :nullify
  has_many :author_transfers, -> { where(transfer_type: :author_revenue) }, through: :orders, source: :transfers, dependent: :nullify
  has_many :reader_transfers, -> { where(transfer_type: :reader_revenue) }, through: :orders, source: :transfers, dependent: :nullify

  has_many :comments, as: :commentable, dependent: :nullify

  has_many :taggings, dependent: :nullify
  has_many :tags, through: :taggings, dependent: :nullify

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify

  validates :asset_id, presence: true, inclusion: { in: SUPPORTED_ASSETS }
  validates :uuid, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 64 }
  validates :intro, presence: true, length: { maximum: 140 }
  validates :content, presence: true
  validate :ensure_author_account_normal
  validate :ensure_price_not_too_low

  before_validation :setup_attributes, on: :create

  default_scope -> { includes(:currency) }
  scope :only_published, -> { where(state: :published) }
  scope :order_by_revenue_usd, lambda {
    joins(:orders)
      .group(:id)
      .select(
        <<~SQL.squish
          articles.*,
          SUM(orders.change_usd) as revenue_usd
        SQL
      ).order(revenue_usd: :desc)
  }
  scope :order_by_popularity, lambda {
    where.not(orders_count: 0)
         .joins(:orders)
         .group(:id)
         .select(
           <<~SQL.squish
             articles.*, 
             (((SUM(orders.change_usd) * 10 + articles.upvotes_count - articles.downvotes_count + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.created_at)) / 3600)::integer + 1), 2))) AS popularity
           SQL
         )
         .order('popularity DESC, created_at DESC')
  }

  after_create :create_wallet!
  after_commit :notify_authoring_subscribers,
               :notify_admin,
               :subscribe_comments_for_author,
               :update_author_statistics_cache,
               on: :create

  delegate :swappable?, to: :currency

  aasm column: :state do
    state :published, initial: true
    state :hidden
    state :blocked

    event :hide do
      transitions from: :published, to: :hidden
    end

    event :publish do
      transitions from: :hidden, to: :published
    end

    event :block, after_commit: :notify_author_blocked do
      transitions from: :hidden, to: :blocked
      transitions from: :published, to: :blocked
    end

    event :unblock, after_commit: :notify_author_unblocked do
      transitions from: :blocked, to: :hidden
    end
  end

  def authorized?(user)
    return if user.blank?
    return true if author == user

    orders.find_by(buyer: user).present?
  end

  def update_revenue
    update revenue: orders.sum(:total)
  end

  def share_of(user)
    return if user.blank?
    return Order::AUTHOR_RATIO if user == author

    user.orders.where(item: self).sum(:total) / revenue * (1 - Order::AUTHOR_RATIO - Order::PRSDIGG_RATIO)
  end

  def notify_authoring_subscribers
    return if hidden?

    ArticlePublishedNotification.with(article: self).deliver(author.authoring_subscribe_by_users)
  end

  def notify_admin
    AdminNotificationService.new.text(
      "#{author.name} 创建了新文章 《#{title}》"
    )
  end

  def subscribe_comments_for_author
    author.create_action :commenting_subscribe, target: self
  end

  def words_count
    content.gsub("\n", '').size
  end

  def partial_content
    return if words_count < 300

    content.truncate((words_count * 0.1).to_i)
  end

  def wallet_id
    @wallet_id = wallet&.uuid
  end

  def notify_author_blocked
    ArticleBlockedNotification.with(article: self).deliver(author)
  end

  def notify_author_unblocked
    ArticleUnblockedNotification.with(article: self).deliver(author)
  end

  def author_revenue_total
    author_transfers.sum(:amount)
  end

  def reader_revenue_total
    reader_transfers.sum(:amount)
  end

  def tag_names
    @tag_names ||= tags.pluck(:name)
  end

  def update_author_statistics_cache
    author.update(
      articles_count: author.articles.count
    )
  end

  def price_usd
    (currency.price_usd.to_f * price).to_f.round(4)
  end

  def revenue_usd
    orders.sum(:change_usd)
  end

  def random_readers(limit = 24)
    readers.where(id: readers.ids.sample(limit))
  end

  private

  def setup_attributes
    return unless new_record?

    assign_attributes(
      price: price.to_f.round(8),
      uuid: SecureRandom.uuid
    )
  end

  def ensure_author_account_normal
    return unless new_record?

    errors.add(:author, 'is banned') if author&.banned?
  end

  def ensure_price_not_too_low
    case asset_id
    when Currency::PRS_ASSET_ID
      errors.add(:price, 'at least 1 PRS') if price.to_f < MINIMUM_PRICE_PRS
    when Currency::BTC_ASSET_ID
      errors.add(:price, 'at least 0.000001 BTC') if price.to_f < MINIMUM_PRICE_BTC
    end
  end
end
