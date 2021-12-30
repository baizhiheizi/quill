# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :integer          not null, primary key
#  name                        :string
#  avatar_url                  :string
#  mixin_id                    :string
#  mixin_uuid                  :uuid
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  authoring_subscribers_count :integer          default("0")
#  reading_subscribers_count   :integer          default("0")
#  banned_at                   :datetime
#  statistics                  :jsonb            default("\"{}\"")
#  locale                      :integer
#  subscribers_count           :integer          default("0")
#  subscribing_count           :integer          default("0")
#  uid                         :string
#
# Indexes
#
#  index_users_on_mixin_id    (mixin_id)
#  index_users_on_mixin_uuid  (mixin_uuid) UNIQUE
#  index_users_on_statistics  (statistics)
#  index_users_on_uid         (uid) UNIQUE
#

class User < ApplicationRecord
  include Authenticatable

  store :statistics, accessors: %i[
    articles_count
    bought_articles_count
    comments_count
    author_revenue_total_prs
    reader_revenue_total_prs
    revenue_total_prs
    payment_total_prs
    author_revenue_total_btc
    reader_revenue_total_btc
    revenue_total_btc
    payment_total_btc
    payment_total_usd
    cached_at
  ]

  has_one :mixin_authorization, -> { where(provider: :mixin) }, class_name: 'UserAuthorization', inverse_of: :user, dependent: :restrict_with_error
  has_one :prs_account, dependent: :restrict_with_error
  has_many :access_tokens, dependent: :destroy

  has_many :articles, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :payments, foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :payer, dependent: :nullify
  has_many :transfers, foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :snapshots, foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :opponent, dependent: :nullify
  has_many :author_revenue_transfers, -> { where(transfer_type: :author_revenue) }, class_name: 'Transfer', foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :reader_revenue_transfers, -> { where(transfer_type: :reader_revenue) }, class_name: 'Transfer', foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :revenue_transfers, -> { where(transfer_type: %w[author_revenue reader_revenue]) }, class_name: 'Transfer', foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :orders, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify
  has_many :buy_orders, -> { where(order_type: %w[buy_article]) }, class_name: 'Order', foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify
  has_many :bought_articles, -> { order(created_at: :desc) }, through: :buy_orders, source: :item, source_type: 'Article'
  has_many :comments, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :swap_orders, through: :payments
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :prs_transactions, through: :prs_account, source: :transactions

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify
  has_one :notification_setting, dependent: :destroy

  before_validation :setup_attributes, on: :create

  validates :name, presence: true
  validates :mixin_id, presence: true
  validates :mixin_uuid, presence: true
  validates :uid, presence: true, uniqueness: true

  enum locale: I18n.available_locales

  after_commit on: :create do
    create_wallet!
    create_notification_setting!
    # create_prs_account!
    update_statistics_cache
    create_bot_contact_conversation_async
  end

  default_scope { includes(:mixin_authorization) }
  scope :active, lambda {
    order_by_articles_count
      .where(
        articles: { created_at: (Time.current - 1.month)..., orders_count: 1... }
      )
  }
  scope :only_banned, -> { where.not(banned_at: nil) }
  scope :without_banned, -> { where(banned_at: nil) }
  scope :order_by_revenue_total, lambda {
    joins(:revenue_transfers)
      .group(:id)
      .select(
        <<~SQL.squish
          users.*,
          SUM(transfers.amount) AS revenue_total
        SQL
      ).order(revenue_total: :desc)
  }
  scope :order_by_orders_total, lambda {
    joins(:orders)
      .group(:id)
      .select(
        <<~SQL.squish
          users.*,
          SUM(orders.value_btc) AS orders_total
        SQL
      ).order(orders_total: :desc)
  }
  scope :order_by_articles_count, lambda {
    joins(:articles)
      .group(:id)
      .select(
        <<~SQL.squish
          users.*,
          COUNT(articles.id) AS articles_count
        SQL
      ).order(articles_count: :desc)
  }
  scope :order_by_comments_count, lambda {
    joins(:comments)
      .group(:id)
      .select(
        <<~SQL.squish
          users.*,
          COUNT(comments.id) AS comments_count
        SQL
      ).order(comments_count: :desc)
  }

  delegate :phone, to: :mixin_authorization

  # subscribe user
  action_store :subscribe, :user, counter_cache: 'subscribers_count', user_counter_cache: 'subscribing_count'
  # subscribe for article's comment
  action_store :commenting_subscribe, :article, counter_cache: 'commenting_subscribers_count'
  # upvote article
  action_store :upvote, :article, counter_cache: true
  # downvote article
  action_store :downvote, :article, counter_cache: true
  # upvote comment
  action_store :upvote, :comment, counter_cache: true
  # downvote comment
  action_store :downvote, :comment, counter_cache: true
  # subscribe for tag's articles
  action_store :subscribe, :tag, counter_cache: 'subscribers_count'

  def unread_notifications_count
    notifications.unread.count
  end

  def has_unread_notification?
    notifications.unread.present?
  end

  def bio
    mixin_authorization&.raw&.[]('biography') || t('user.default_bio')
  end

  def banned?
    banned_at?
  end

  def ban!
    update banned_at: Time.current

    prs_account.deny_on_chain_async
    UserBannedNotification.with(user: self).deliver(self)
  end

  def unban!
    update banned_at: nil

    prs_account.allow_on_chain_async
    UserUnbannedNotification.with(user: self).deliver(self)
  end

  def update_statistics_cache
    update statistics: {
      articles_count: articles.count,
      author_revenue_total_prs: author_revenue_transfers.only_prs.sum(:amount).to_f,
      author_revenue_total_btc: author_revenue_transfers.only_btc.sum(:amount).to_f,
      bought_articles_count: bought_articles.count,
      comments_count: comments.count,
      reader_revenue_total_prs: reader_revenue_transfers.only_prs.sum(:amount).to_f,
      reader_revenue_total_btc: reader_revenue_transfers.only_btc.sum(:amount).to_f,
      revenue_total_prs: revenue_transfers.only_prs.sum(:amount).to_f,
      revenue_total_btc: revenue_transfers.only_btc.sum(:amount).to_f,
      payment_total_prs: orders.only_prs.sum(:total).to_f,
      payment_total_btc: orders.only_btc.sum(:total).to_f,
      payment_total_usd: orders.sum(:value_usd).to_f,
      cached_at: Time.current
    }
  end

  def author_revenue_total_usd
    (statistics['author_revenue_total_prs'].to_f * Currency.prs.price_usd.to_f) + (statistics['author_revenue_total_btc'].to_f * Currency.btc.price_usd.to_f)
  end

  def reader_revenue_total_usd
    (statistics['reader_revenue_total_prs'].to_f * Currency.prs.price_usd.to_f) + (statistics['reader_revenue_total_btc'].to_f * Currency.btc.price_usd.to_f.to_f)
  end

  def revenue_total_usd
    author_revenue_total_usd + reader_revenue_total_usd
  end

  def payment_total_usd
    statistics['payment_total_usd'] || 0.0
  end

  def update_profile(profile = nil)
    profile ||= mixin_authorization.raw
    return if profile.blank?

    update(
      avatar_url: profile['avatar_url'],
      name: profile['full_name']
    )
  end

  def wallet_id
    @wallet_id = (wallet.presence || create_wallet)&.uuid
  end

  def avatar
    avatar_url.presence || generated_avatar_url
  end

  def generated_avatar_url
    format('https://api.multiavatar.com/%<mixin_uuid>s.svg', mixin_uuid: mixin_uuid)
  end

  def accessable?
    return true unless Settings.whitelist&.enable

    mixin_id_in_whitelist? || phone_country_code_in_whitelist?
  end

  def mixin_id_in_whitelist?
    mixin_id.in? (Settings.whitelist&.mixin_id || []).map(&:to_s)
  end

  def phone_country_code_in_whitelist?
    Regexp.new("^\\+?(#{Settings.whitelist&.phone_country_code&.join('|')})\\d+").match? phone
  end

  def mixin_authorization_valid?
    if Settings.whitelist&.enable && Settings.whitelist&.phone_country_code.present?
      phone.present?
    else
      true
    end
  end

  def create_bot_contact_conversation_async
    UserCreateBotContactConversationWorker.perform_async id
  end

  def create_bot_contact_conversation
    PrsdiggBot.api.create_contact_conversation mixin_uuid
    RevenueBot.api.create_contact_conversation(mixin_uuid) if RevenueBot.api.present?
  end

  def available_articles
    (
      bought_articles.only_published.to_a +
        articles.only_published.or(Article.only_free.only_published).to_a
    ).uniq
  end

  def to_param
    uid
  end

  def fennec?
    mixin_id == '0' || mixin_id.match?(/^7000\d{6}/)
  end

  def messenger?
    !fennec?
  end

  private

  def setup_attributes
    self.uid =
      if mixin_id == '0'
        SecureRandom.alphanumeric 10
      else
        mixin_id
      end
  end
end
