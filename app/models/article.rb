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

  include AASM

  belongs_to :author, class_name: 'User', inverse_of: :articles

  has_many :orders, as: :item, dependent: :nullify
  has_many :buy_orders, -> { where(order_type: :buy_article) }, class_name: 'Order', as: :item, dependent: :nullify, inverse_of: false
  has_many :reward_orders, -> { where(order_type: :reward_article) }, class_name: 'Order', as: :item, dependent: :nullify, inverse_of: false
  has_many :readers, -> { distinct }, through: :orders, source: :buyer
  has_many :buyers, -> { distinct }, through: :buy_orders, source: :buyer
  has_many :rewarders, -> { distinct }, through: :reward_orders, source: :buyer
  has_many :comments, as: :commentable, dependent: :nullify

  validates :uuid, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 25 }
  validates :intro, presence: true, length: { maximum: 140 }
  validates :content, presence: true
  validates :price, numericality: { greater_than: 0.00000001 }

  before_validation :setup_attributes, on: :create

  scope :only_published, -> { where(state: :published) }
  scope :order_by_popularity, lambda {
                                where(state: :published)
                                  .where.not(orders_count: 0)
                                  .select(
                                    <<~SQL.squish
                                      articles.*, 
                                      ((((articles.revenue / articles.price) + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.created_at)) / 3600)::integer + 1), 2))) AS popularity
                                    SQL
                                  )
                                  .order('popularity DESC, created_at DESC')
                              }

  after_commit :notify_subsribers_async, :subscribe_comments_for_author, on: :create

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

    event :block do
      transitions from: :hidden, to: :blocked
      transitions from: :published, to: :blocked
    end

    event :unblock do
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

  def notify_subsribers_async
    return if hidden?

    messages = subscribers.pluck(:mixin_uuid).map do |_uuid|
      MixinBot.api.app_card(
        conversation_id: MixinBot.api.unique_conversation_id(_uuid),
        recipient_id: _uuid,
        data: {
          icon_url: 'https://mixin-images.zeromesh.net/L0egX-GZxT0Yh-dd04WKeAqVNRzgzuj_Je_-yKf8aQTZo-xihd-LogbrIEr-WyG9WbJKGFvt2YYx-UIUa1qQMRla=s256',
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

  def subscribe_comments_for_author
    author.create_action :commenting_subscribe, target: self
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
end
