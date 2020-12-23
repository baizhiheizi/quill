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
#  state                               :string
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
#  index_articles_on_author_id  (author_id)
#  index_articles_on_uuid       (uuid) UNIQUE
#
class Article < ApplicationRecord
  PRS_ASSET_ID = '3edb734c-6d6f-32ff-ab03-4eb43640c758'
  PRS_ICON_URL = 'https://mixin-images.zeromesh.net/1fQiAdit_Ji6_Pf4tW8uzutONh9kurHhAnN4wqEIItkDAvFTSXTMwlk3AB749keufDFVoqJb5fSbgz7K2HoOV7Q=s128'
  PRSDIGG_ICON_URL = 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256'

  include AASM

  belongs_to :author, class_name: 'User', inverse_of: :articles

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

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify

  validates :uuid, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 25 }
  validates :intro, presence: true, length: { maximum: 140 }
  validates :content, presence: true
  validates :price, numericality: { greater_than: 0.000_000_01 }
  validate :ensure_author_account_normal

  before_validation :setup_attributes, on: :create

  scope :only_published, -> { where(state: :published) }
  scope :order_by_popularity, lambda {
                                where.not(orders_count: 0)
                                     .select(
                                       <<~SQL.squish
                                         articles.*, 
                                         ((((articles.revenue / articles.price) + articles.upvotes_count - articles.downvotes_count + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.created_at)) / 3600)::integer + 1), 2))) AS popularity
                                       SQL
                                     )
                                     .order('popularity DESC, created_at DESC')
                              }

  after_create :create_wallet!
  after_commit :notify_subsribers, :subscribe_comments_for_author, :notify_admin, on: :create

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

  def subscribers
    @subscribers = author.authoring_subscribe_by_users
  end

  def notify_subsribers
    return if hidden?

    messages = subscribers.pluck(:mixin_uuid).map do |_uuid|
      PrsdiggBot.api.app_card(
        conversation_id: PrsdiggBot.api.unique_conversation_id(_uuid),
        recipient_id: _uuid,
        data: {
          icon_url: PRSDIGG_ICON_URL,
          title: title.truncate(36),
          description: format('%<author_name>s 新文章', author_name: author.name),
          action: format('%<host>s/articles/%<uuid>s', host: Rails.application.credentials.fetch(:host), uuid: uuid)
        }
      )
    end

    messages.each do |message|
      SendMixinMessageWorker.perform_async message
    end
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
    TextNotificationService.new.call(
      "您的文章《#{title}》已被管理员屏蔽。如有异议，可直接回复信息，进行申诉。",
      recipient_id: author.mixin_uuid
    )
  end

  def notify_author_unblocked
    TextNotificationService.new.call(
      "您的文章《#{title}》已被管理员撤销屏蔽。",
      recipient_id: author.mixin_uuid
    )
  end

  def author_revenue_amount
    author_transfers.sum(:amount)
  end

  def reader_revenue_amount
    reader_transfers.sum(:amount)
  end

  private

  def setup_attributes
    return unless new_record?

    assign_attributes(
      asset_id: PRS_ASSET_ID,
      price: price.round(8),
      uuid: SecureRandom.uuid
    )
  end

  def ensure_author_account_normal
    return unless new_record?

    errors.add(:author, 'account is banned!') if author&.banned?
  end
end
