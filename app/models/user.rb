# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  articles_count              :integer          default(0), not null
#  authoring_subscribers_count :integer          default(0)
#  biography                   :text
#  blocked_at                  :datetime
#  blocking_count              :integer          default(0)
#  blocks_count                :integer          default(0)
#  comments_count              :integer          default(0), not null
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
#  index_users_on_name_trgm   (name) USING gin
#  index_users_on_uid         (uid) UNIQUE
#

class User < ApplicationRecord
  is_impressionable

  include Users::EmailVerifiable
  include Users::Scopable
  include Users::Statable

  extend Enumerize

  # Canonical preload chain for any caller that renders `shared/_avatar`
  # (or `admin/users/_field`, which delegates to it). The chain mirrors
  # `UserFieldPreloads#user_field_preloads` in
  # `app/controllers/concerns/user_field_preloads.rb` — both partials
  # resolve `user.avatar_image_thumb` / `user.avatar_image_url`, which
  # walks:
  #   - `authorization&.raw["avatar_url"]` (OAuth fallback when no
  #     ActiveStorage avatar is attached)
  #   - `avatar.attached?` (the `attachments` row)
  #   - `avatar.key` (the blob)
  #   - `avatar.variant(:thumb).processed.key` (the variant chain:
  #     `variant_records → image_attachment → blob`)
  #
  # Without these preloads each row fires 4-5 SELECTs. The constant
  # exists so non-controller callers (Article scopes, test factories,
  # background jobs) can include the chain with the same shape that
  # `Admin::BaseController#admin_user_field_preloads` already uses
  # inline — keeping them byte-for-byte identical avoids drift between
  # the controller helper and the model-level eager-load.
  AVATAR_PRELOADS = [
    :authorization,
    {
      avatar_attachment: {
        blob: {
          variant_records: { image_attachment: :blob },
          preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } }
        }
      }
    }
  ].freeze

  # The primary auth record. Mixin is the active sign-in provider; fennec
  # and mvm_eth are retired but their historical UserAuthorization rows are
  # kept (those users still exist — like future Google/GitHub users pre-OAuth).
  has_one :authorization, -> { where(provider: %w[mixin fennec mvm_eth]) }, class_name: "UserAuthorization", inverse_of: :user, dependent: :restrict_with_exception
  has_many :user_authorizations, dependent: :restrict_with_exception
  has_one :twitter_authorization, -> { where(provider: :twitter) }, class_name: "UserAuthorization", inverse_of: :user, dependent: :restrict_with_exception

  has_many :access_tokens, -> { kept }, dependent: :destroy

  has_many :articles, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :payments, foreign_key: :payer_id, primary_key: :mixin_uuid, inverse_of: :payer, dependent: :nullify
  has_many :transfers, foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :snapshots, foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :opponent, dependent: :nullify
  has_many :author_revenue_transfers, -> { where(transfer_type: :author_revenue) }, class_name: "Transfer", foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :reader_revenue_transfers, -> { where(transfer_type: :reader_revenue) }, class_name: "Transfer", foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :revenue_transfers, -> { where(transfer_type: %w[author_revenue reader_revenue]) }, class_name: "Transfer", foreign_key: :opponent_id, primary_key: :mixin_uuid, inverse_of: :recipient, dependent: :nullify
  has_many :orders, foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify
  has_many :buy_orders, -> { where(order_type: %w[buy_article]) }, class_name: "Order", foreign_key: :buyer_id, inverse_of: :buyer, dependent: :nullify
  has_many :bought_articles, -> { order(created_at: :desc) }, through: :buy_orders, source: :item, source_type: "Article"
  has_many :comments, foreign_key: :author_id, inverse_of: :author, dependent: :nullify
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :bonuses, dependent: :restrict_with_exception
  has_many :pre_orders, primary_key: :mixin_uuid, foreign_key: :payer_id, dependent: :restrict_with_exception, inverse_of: :payer
  has_many :sessions, dependent: :restrict_with_exception

  has_one :wallet, class_name: "MixinNetworkUser", as: :owner, dependent: :nullify
  has_one :notification_setting, dependent: :destroy

  has_many :collections, primary_key: :mixin_uuid, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_exception

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 64, 64 ]
  end

  validates :name, presence: true
  validates :email, uniqueness: true, format: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_nil: true
  validates :mixin_id, presence: true
  validates :mixin_uuid, presence: true
  validates :uid, presence: true, uniqueness: true

  enumerize :locale, in: I18n.available_locales, default: I18n.default_locale

  after_commit :prepare_async, on: :create

  delegate :phone, to: :authorization, allow_nil: true

  # subscribe user
  action_store :subscribe, :user, counter_cache: "subscribers_count", user_counter_cache: "subscribing_count"
  # subscribe for article's comment
  action_store :commenting_subscribe, :article, counter_cache: "commenting_subscribers_count"
  # upvote article
  action_store :upvote, :article, counter_cache: true
  # downvote article
  action_store :downvote, :article, counter_cache: true
  # upvote comment
  action_store :upvote, :comment, counter_cache: true
  # downvote comment
  action_store :downvote, :comment, counter_cache: true
  # subscribe for tag's articles
  action_store :subscribe, :tag, counter_cache: "subscribers_count"
  # block user
  action_store :block, :user, counter_cache: true, user_counter_cache: "blocking_count"

  def has_safe?
    authorization&.has_safe?
  end

  def bio
    biography || authorization&.biography || I18n.t("activerecord.attributes.user.default_bio")
  end

  # Reads the user's Mixin wallet UUID only — must not trigger `create_wallet`,
  # since provisioning a Mixin Network user now costs 0.5 USDT
  # (MixinBot::CREATE_USER_BILLING_INCREMENT). `wallet` association still loads
  # existing wallets (legacy rows); new wallets are created explicitly via the
  # admin tooling, never as a side effect of a read. See #1797.
  def wallet_id
    @wallet_id = wallet&.uuid
  end

  def avatar_image_url
    @avatar_image_url =
      if avatar.attached?
        [ Settings.storage.endpoint, avatar.key ].join("/")
      else
        authorization&.avatar_url.presence
      end
  end

  def avatar_image_thumb
    @avatar_image_thumb =
      if avatar.attached?
        [ Settings.storage.endpoint, avatar.variant(:thumb).processed.key ].join("/")
      else
        authorization&.raw&.[]("avatar_url").presence&.gsub(/s256\Z/, "s64")
      end
  rescue LoadError, StandardError
    avatar_image_url
  end

  def avatar_url
    avatar_image_url || self.class.default_avatar_url
  end

  def avatar_thumb
    avatar_image_thumb || self.class.default_avatar_url
  end

  def self.default_avatar_url
    ActionController::Base.helpers.asset_url(Settings.icon_file)
  end

  def prepare
    create_notification_setting! if notification_setting.blank?
    create_bot_contact_conversation
  end

  def prepare_async
    Users::PrepareJob.perform_later id
  end

  def create_bot_contact_conversation
    return unless messenger?

    QuillBot.api.create_contact_conversation mixin_uuid
    RevenueBot.api.create_contact_conversation(mixin_uuid) if RevenueBot.api.present?
  end

  def available_articles
    Article
      .where(id: bought_articles.only_published.select(:id))
      .or(articles.only_published)
      .or(Article.only_free.only_published)
      .distinct
  end

  # SQL subquery that returns every user_id that subscribed to `self`.
  # The action_store gem's `subscribe_by_user_ids` materializes the full
  # list of subscriber ids into a Ruby array first; this relation lets
  # callers push the predicate straight into the database instead.
  # Matches the NOT IN / IN subquery pattern used by
  # `HomeController#active_authors` (PR #1735) and
  # `ArticleSearchService#filter_block_authors`.
  def subscribed_user_ids_relation
    Action
      .where(target_type: "User", target_id: id, action_type: "subscribe")
      .select(:user_id)
  end

  # SQL subquery that returns every user_id that `self` has blocked.
  # The action_store gem's `block_user_ids` materializes the list into
  # Ruby first; this relation keeps the predicate in SQL. See
  # `subscribed_user_ids_relation` for context.
  def blocked_user_ids_relation
    Action
      .where(user_type: "User", user_id: id, target_type: "User", action_type: "block")
      .select(:target_id)
  end

  def owning_collection_ids
    Collection.joins(:buy_orders).where(buy_orders: { buyer_id: id }).distinct.pluck(:uuid)
  end

  def to_param
    uid
  end

  def notify_for_login
    UserConnectedNotifier.with(record: self, user: self).deliver(self)
  end

  def notify_for_safe_registration
    return if has_safe?

    UserSafeRegistrationNotifier.with(record: self, user: self).deliver(self)
  end

  def short_uid
    return uid if messenger?

    uid.first(6)
  end

  def default_payment
    "MixinPreOrder" if messenger?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name mixin_id id uid email locale]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[authorization articles]
  end
end
