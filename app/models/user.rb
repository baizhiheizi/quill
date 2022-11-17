# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                          :bigint           not null, primary key
#  authoring_subscribers_count :integer          default(0)
#  biography                   :text
#  blocked_at                  :datetime
#  blocking_count              :integer          default(0)
#  blocks_count                :integer          default(0)
#  email                       :string
#  email_verified_at           :datetime
#  locale                      :string
#  mixin_uuid                  :uuid
#  name                        :string
#  reading_subscribers_count   :integer          default(0)
#  subscribers_count           :integer          default(0)
#  subscribing_count           :integer          default(0)
#  uid                         :string
#  validated_at                :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mixin_id                    :string
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_mixin_id    (mixin_id)
#  index_users_on_mixin_uuid  (mixin_uuid) UNIQUE
#  index_users_on_uid         (uid) UNIQUE
#

class User < ApplicationRecord
  second_level_cache expires_in: 1.week

  include Authenticatable
  include Users::EmailVerifiable
  include Users::Importable
  include Users::Scopable
  include Users::Statable
  include Users::CollectibleReadable

  extend Enumerize

  has_one :authorization, class_name: 'UserAuthorization', inverse_of: :user, dependent: :restrict_with_error
  has_many :access_tokens, dependent: :destroy

  has_many :articles, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :payments, foreign_key: :payer_id, primary_key: :mixin_uuid, inverse_of: :payer, dependent: :nullify
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
  has_many :pre_orders, primary_key: :mixin_uuid, foreign_key: :payer_id, dependent: :restrict_with_exception, inverse_of: :payer
  has_many :sessions, dependent: :restrict_with_exception

  has_many :arweave_transactions, primary_key: :mixin_uuid, foreign_key: :owner_id, dependent: :restrict_with_exception, inverse_of: :owner

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify
  has_one :notification_setting, dependent: :destroy

  has_many :non_fungible_outputs, primary_key: :mixin_uuid, dependent: :nullify
  has_many :unspent_non_fungible_outputs, -> { where(state: :unspent) }, primary_key: :mixin_uuid, class_name: 'NonFungibleOutput', dependent: :restrict_with_exception, inverse_of: :user
  has_many :collectibles, through: :unspent_non_fungible_outputs

  has_many :collections, primary_key: :mixin_uuid, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_exception

  has_one_attached :avatar

  validates :name, presence: true
  validates :email, uniqueness: true, format: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_nil: true
  validates :mixin_id, presence: true
  validates :mixin_uuid, presence: true
  validates :uid, presence: true, uniqueness: true

  enumerize :locale, in: I18n.available_locales, default: I18n.default_locale

  after_commit :prepare_async, on: :create

  delegate :phone, :public_key, to: :authorization

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

  def bio
    biography || authorization.biography || I18n.t('activerecord.attributes.user.default_bio')
  end

  def wallet_id
    @wallet_id = (wallet.presence || create_wallet)&.uuid
  end

  def avatar_url
    @avatar_url =
      if avatar.attached?
        [Settings.storage.endpoint, avatar.key].join('/')
      else
        authorization.avatar_url.presence || generated_avatar_url
      end
  end

  def avatar_thumb
    @avatar_thumb =
      if avatar.attached?
        [Settings.storage.endpoint, avatar.variant(resize_to_fit: [64, 64]).key].join('/')
      else
        authorization.raw&.[]('avatar_url').presence&.gsub(/s256\Z/, 's64') || generated_avatar_url
      end
  end

  def generated_avatar_url
    format('https://api.multiavatar.com/%<mixin_uuid>s.png', mixin_uuid: mixin_uuid)
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

    QuillBot.api.create_contact_conversation mixin_uuid
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

  def default_payment
    if messenger?
      'MixinPreOrder'
    elsif fennec?
      'FennecPreOrder'
    elsif mvm_eth?
      'MVMPreOrder'
    end
  end
end
