# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  authoring_subscribers_count :integer          default(0)
#  avatar_url                  :string
#  banned_at                   :datetime
#  blocking_count              :integer          default(0)
#  blocks_count                :integer          default(0)
#  locale                      :integer
#  mixin_uuid                  :uuid
#  name                        :string
#  reading_subscribers_count   :integer          default(0)
#  subscribers_count           :integer          default(0)
#  subscribing_count           :integer          default(0)
#  uid                         :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mixin_id                    :string
#
# Indexes
#
#  index_users_on_mixin_id    (mixin_id)
#  index_users_on_mixin_uuid  (mixin_uuid) UNIQUE
#  index_users_on_uid         (uid) UNIQUE
#

class User < ApplicationRecord
  include Authenticatable

  has_one :authorization, class_name: 'UserAuthorization', inverse_of: :user, dependent: :restrict_with_error
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
  has_many :bonuses, dependent: :restrict_with_exception

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify
  has_one :notification_setting, dependent: :destroy

  validates :name, presence: true
  validates :mixin_id, presence: true
  validates :mixin_uuid, presence: true
  validates :uid, presence: true, uniqueness: true

  enum locale: I18n.available_locales

  after_commit :prepare_async, on: :create

  default_scope { includes(:authorization) }
  scope :only_mixin_messenger, -> { where(authorization: { provider: :mixin }) }
  scope :only_fennec, -> { where(authorization: { provider: :fennec }) }

  scope :active, lambda {
    order_by_articles_count
      .where(
        articles: { created_at: (1.month.ago)..., orders_count: 1... }
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

  delegate :phone, to: :authorization

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
  # block user
  action_store :block, :user, counter_cache: true, user_counter_cache: 'blocking_count'

  def unread_notifications_count
    notifications.unread.count
  end

  def has_unread_notification?
    notifications.unread.present?
  end

  def bio
    authorization&.raw&.[]('biography') || I18n.t('activerecord.attributes.user.default_bio')
  end

  def banned?
    banned_at?
  end

  def ban!
    update banned_at: Time.current

    UserBannedNotification.with(user: self).deliver(self)
  end

  def unban!
    update banned_at: nil

    UserUnbannedNotification.with(user: self).deliver(self)
  end

  def articles_count
    @articles_count ||= articles.count
  end

  def bought_articles_count
    @bought_articles_count ||= bought_articles.count
  end

  def comments_count
    @comments_count ||= comments.count
  end

  def payment_total_usd
    @payment_total_usd ||= orders.sum(:value_usd).to_f
  end

  def author_revenue_total_usd
    @author_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :author_revenue).sum('amount * currencies.price_usd').to_f
  end

  def reader_revenue_total_usd
    @reader_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :reader_revenue).sum('amount * currencies.price_usd').to_f
  end

  def revenue_total_usd
    @revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: %i[author_revenue reader_revenue]).sum('amount * currencies.price_usd').to_f
  end

  def update_profile(profile = nil)
    profile ||= authorization.raw
    return if profile.blank?

    update(
      avatar_url: profile['avatar_url'],
      name: profile['full_name']
    )
  end

  def wallet_id
    @wallet_id = (wallet.presence || create_wallet)&.uuid
  end

  def avatar(original: false)
    @avatar =
      if avatar_url.blank?
        generated_avatar_url
      elsif original
        avatar_url
      else
        avatar_url.presence&.gsub(/s256\Z/, 's64')
      end
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

  def prepare
    create_wallet! if wallet.blank?
    create_notification_setting! if notification_setting.blank?
    create_bot_contact_conversation
  end

  def prepare_async
    UserPrepareWorker.perform_async id
  end

  def create_bot_contact_conversation
    return unless messenger?

    BatataBot.api.create_contact_conversation mixin_uuid
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
    authorization.provider == 'fennec'
  end

  def messenger?
    authorization.provider == 'mixin'
  end

  def mvm_eth?
    authorization.provider == 'mvm_eth'
  end

  def mixin_deposit_url
    "mixin://transfer/#{mixin_uuid}"
  end

  def mvm_deposit_address(asset_id)
    return unless mvm_eth?
    return if asset_id.blank?

    r = authorization.mixin_api.asset asset_id
    r['deposit_entries'].first
  rescue MixinBot::Error
    {}
  end

  def mvm_address_url
    return unless mvm_eth?

    Addressable::URI.new(
      scheme: 'https',
      host: 'scan.mvm.dev',
      path: "address/#{uid}"
    ).to_s
  end

  def notify_for_login
    UserConnectedNotification.with(user: self).deliver(self)
  end

  def short_uid
    return uid if messenger?

    uid.first(6)
  end

  def short_name
    return name unless mvm_eth?

    "#{name.first(6)}...#{name.last(4)}"
  end

  def may_claim_faucet?
    return unless mvm_eth?

    faucet_bonus.blank?
  end

  def claim_faucet!
    return unless may_claim_faucet?

    deposit = authorization.mixin_api.snapshots['data'].find(&->(snapshot) { snapshot['type'] == 'deposit' })
    return if deposit.blank?

    deposit_asset = Currency.find_or_create_by asset_id: deposit['asset_id']
    bonus =
      bonuses.create!(
        asset_id: Currency::XIN_ASSET_ID,
        title: 'Faucet',
        description: "Desposited #{deposit['amount']} #{deposit_asset.symbol}",
        amount: Bonus::XIN_FAUCET_AMOUNT
      )
    bonus.deliver!
  end

  def faucet_bonus
    @faucet_bonus = bonuses.find_by(asset_id: Currency::XIN_ASSET_ID, title: 'Faucet')
  end
end
