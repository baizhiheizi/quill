# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                                  :bigint           not null, primary key
#  author_revenue_ratio                :float            default(0.5)
#  commenting_subscribers_count        :integer          default(0)
#  comments_count                      :integer          default(0), not null
#  content                             :text
#  downvotes_count                     :integer          default(0)
#  intro                               :string
#  locale                              :string
#  orders_count                        :integer          default(0), not null
#  platform_revenue_ratio              :float            default(0.1)
#  price                               :decimal(, )      not null
#  published_at                        :datetime
#  readers_revenue_ratio               :float            default(0.4)
#  references_revenue_ratio            :float            default(0.0)
#  revenue_btc                         :decimal(, )      default(0.0)
#  revenue_usd                         :decimal(, )      default(0.0)
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
#  collection_id                       :bigint
#
# Indexes
#
#  index_articles_on_asset_id       (asset_id)
#  index_articles_on_author_id      (author_id)
#  index_articles_on_collection_id  (collection_id)
#  index_articles_on_uuid           (uuid) UNIQUE
#

class Article < ApplicationRecord
  SUPPORTED_ASSETS = Settings.supported_assets || [Currency::BTC_ASSET_ID]
  AUTHOR_REVENUE_RATIO_DEFAULT = 0.5
  READERS_REVENUE_RATIO_DEFAULT = 0.4
  PLATFORM_REVENUE_RATIO_DEFAULT = 0.1

  include AASM

  belongs_to :author, class_name: 'User', inverse_of: :articles
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :articles

  has_many :orders, as: :item, dependent: :restrict_with_error
  has_many :buy_orders, -> { where(order_type: :buy_article) }, class_name: 'Order', as: :item, dependent: :restrict_with_error, inverse_of: false
  has_many :reward_orders, -> { where(order_type: :reward_article) }, class_name: 'Order', as: :item, dependent: :restrict_with_error, inverse_of: false
  has_many :cite_orders, -> { where(order_type: :cite_article) }, class_name: 'Order', as: :item, dependent: :restrict_with_error, inverse_of: false

  has_many :readers, -> { distinct }, through: :orders, source: :buyer
  has_many :buyers, -> { distinct }, through: :buy_orders, source: :buyer
  has_many :rewarders, -> { distinct }, through: :reward_orders, source: :buyer

  has_many :transfers, through: :orders, dependent: :restrict_with_error
  has_many :author_transfers, -> { where(transfer_type: :author_revenue) }, through: :orders, source: :transfers, dependent: :restrict_with_error
  has_many :reader_transfers, -> { where(transfer_type: :reader_revenue) }, through: :orders, source: :transfers, dependent: :restrict_with_error

  has_many :comments, as: :commentable, dependent: :restrict_with_error

  has_many :taggings, dependent: :nullify
  has_many :tags, through: :taggings, dependent: :restrict_with_error

  has_many :snapshots, class_name: 'ArticleSnapshot', primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :article, dependent: :destroy

  has_many :article_references, class_name: 'CiterReference', as: :citer, dependent: :destroy
  has_many :references, through: :article_references, source: :reference, source_type: 'Article'
  has_many :article_citers, class_name: 'CiterReference', as: :reference, dependent: :restrict_with_error
  has_many :citers, through: :article_citers, source: :citer, source_type: 'Article'

  has_many :arweave_transactions, primary_key: :uuid, foreign_key: :article_uuid, dependent: :restrict_with_error, inverse_of: :article

  has_many_attached :images

  accepts_nested_attributes_for :article_references, reject_if: proc { |attributes| attributes['reference_id'].blank? || attributes['revenue_ratio'].blank? }, allow_destroy: true

  has_one :wallet, class_name: 'MixinNetworkUser', as: :owner, dependent: :nullify

  validates :asset_id, inclusion: { in: SUPPORTED_ASSETS }, if: :new_record?
  validates :uuid, presence: true, uniqueness: true
  validates :title, length: { maximum: 64 }
  validates :intro, length: { maximum: 140 }
  validates :title, presence: true, unless: :drafted?
  validates :intro, presence: true, unless: :drafted?
  validates :content, presence: true, unless: :drafted?
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validates :platform_revenue_ratio, presence: true, numericality: { equal_to: 0.1 }
  validates :readers_revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.4 }
  validates :author_revenue_ratio, presence: true, numericality: { less_than_or_equal_to: 0.5 }
  validates :references_revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validate :ensure_price_not_too_low
  validate :ensure_references_ratios_correct
  validate :ensure_revenue_ratios_sum_to_one
  validate :can_not_change_currency_after_published

  before_validation :setup_attributes, on: :create
  before_validation :set_default_intro
  after_save do
    generate_snapshot if should_generate_snapshot?
    if saved_change_to_content
      attach_images_from_content_async
      detect_locale_async
    end
  end

  delegate :swappable?, to: :currency

  default_scope -> { includes(:currency) }
  scope :without_blocked, -> { where.not(state: :blocked) }
  scope :without_free, -> { where('price > ?', 0) }
  scope :only_free, -> { where(price: 0.0) }
  scope :only_drafted, -> { where(state: :drafted) }
  scope :only_published, -> { where(state: :published) }
  scope :without_drafted, -> { where.not(state: :drafted) }
  scope :order_by_revenue_usd, -> { order(revenue_usd: :desc) }
  scope :order_by_popularity, lambda {
    joins(:orders)
      .group(:id)
      .select(
        <<~SQL.squish
          articles.*, 
          (((SUM(orders.value_usd) * 10 + articles.upvotes_count - articles.downvotes_count - articles.downvotes_count * AVG(orders.value_usd) * 20 + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.published_at)) / 3600)::integer + 1), 2))) AS popularity
        SQL
      )
      .order('popularity DESC, published_at DESC')
  }

  aasm column: :state do
    state :drafted, initial: true
    state :published
    state :hidden
    state :blocked

    event :hide do
      transitions from: :published, to: :hidden
    end

    event :publish, guards: :ensure_content_valid, after: %i[do_first_publish] do
      transitions from: :drafted, to: :published
      transitions from: :hidden, to: :published
    end

    event :block do
      transitions from: :published, to: :blocked
      transitions from: :hidden, to: :blocked
    end

    event :unblock do
      transitions from: :blocked, to: :hidden
    end
  end

  def free?
    price.zero?
  end

  def may_buy_by?(user = nil)
    return false if author.block_user?(user)
    return false if user&.block_user?(author)

    published?
  end

  def authorized?(user = nil)
    return true if (published? && free?) || author == user
    return if user.blank?

    orders.find_by(buyer: user).present?
  end

  def update_revenue
    update revenue_usd: orders.sum(:value_usd), revenue_btc: orders.sum(:value_btc)
  end

  def share_of(user)
    return if user.blank?
    return author_revenue_ratio if user == author
    return if revenue_btc.to_f.zero?

    user.orders.where(item: self).sum(:value_btc) / revenue_btc * readers_revenue_ratio
  end

  def notify_subscribers
    ArticlePublishedNotification
      .with(article: self)
      .deliver(
        User.where(id: (author.subscribe_by_user_ids - author.block_user_ids))
      )
  end

  def notify_admin
    AdminNotificationService.new.text(
      "#{author.name} 创建了新文章 《#{title}》"
    )
  end

  def subscribe_comments_for_author
    author.create_action :commenting_subscribe, target: self
  end

  def plain_text
    @plain_text ||= ActionController::Base.helpers.strip_tags(MarkdownRenderService.call(content.strip))
  end

  def words_count
    @words_count ||= plain_text.scan(/[a-zA-Z]+|\S/).size
  end

  def partial_content
    return if words_count < 300

    plain_text.truncate((words_count * 0.1).to_i)
  end

  def wallet_id
    @wallet_id = wallet&.uuid
  end

  def author_revenue_usd
    @author_revenue_usd ||= author_transfers.includes(:currency).sum('amount * currencies.price_usd')
  end

  def reader_revenue_usd
    @reader_revenue_usd ||= reader_transfers.includes(:currency).sum('amount * currencies.price_usd')
  end

  def tag_names
    @tag_names ||= tags.pluck(:name)
  end

  def price_tag
    "#{format('%.8f', price).gsub(/0+\z/, '0')} #{currency.symbol}"
  end

  def price_usd
    (currency.price_usd.to_f * price).to_f.round(4)
  end

  def random_readers(limit = 24)
    readers.where(id: readers.ids.sample(limit))
  end

  def touch_published_at
    update published_at: Time.current if published_at.blank?
  end

  def notify_for_first_published
    notify_subscribers
    taggings.map(&:notify_subscribers)
    notify_admin
  end

  def notify_for_first_published_async
    ArticleNotifyForFirstPublishedWorker.perform_async id
  end

  def create_wallet_async
    ArticleCreateWalletWorker.perform_async id
  end

  def do_first_publish
    return unless published?
    return if published_at.present?

    touch_published_at
    create_wallet_async
    notify_for_first_published_async
    subscribe_comments_for_author
  end

  def sign_on_arweave_as_author
    arweave_transactions.create(
      signer: author,
      article_snapshot: snapshots.order(created_at: :desc).first
    )
  end

  def generate_snapshot
    snapshots.create raw: as_json
  end

  def should_generate_snapshot?
    return if drafted?

    saved_change_to_content? || saved_change_to_title? || saved_change_to_intro? || saved_change_to_published_at?
  end

  def revenue_ratios_sum
    [
      platform_revenue_ratio,
      readers_revenue_ratio,
      author_revenue_ratio,
      references_revenue_ratio
    ].sum
  end

  def to_param
    uuid
  end

  def content_as_html
    MarkdownRenderService.call content.strip, type: :full
  end

  def default_intro
    content.to_s.strip.gsub("\n", '').truncate(140)
  end

  def upvote_ratio
    return if upvotes_count.zero? && downvotes_count.zero?

    "#{format('%.0f', upvotes_count.to_f * 100 / (upvotes_count + downvotes_count))}%"
  end

  def ensure_content_valid
    title.present? && content.present?
  end

  def payment_trace_id(user)
    return if user.blank?

    # generate a unique trace ID for paying
    # avoid duplicate payment
    candidate = QuillBot.api.unique_uuid(uuid, user.mixin_uuid)
    loop do
      break unless Payment.exists?(trace_id: candidate)

      candidate = QuillBot.api.unique_uuid(uuid, candidate)
    end

    candidate
  end

  def buy_url(user, pay_asset_id = asset_id)
    amount = buy_payment_amount pay_asset_id
    return if amount.blank?

    trace_id = payment_trace_id user

    pay_url user, pay_asset_id, amount, buy_payment_memo, trace_id
  end

  def reward_url(user, pay_asset_id, amount, trace_id)
    pay_url user, pay_asset_id, amount, reward_payment_memo, trace_id
  end

  def pay_url(user, pay_asset_id, amount, memo, trace_id)
    Addressable::URI.new(
      scheme: 'mixin',
      host: 'pay',
      path: '',
      query_values: [
        ['recipient', user&.wallet_id || wallet_id],
        ['trace', trace_id],
        ['memo', memo],
        ['asset', pay_asset_id],
        ['amount', amount.to_r.to_f]
      ]
    ).to_s
  end

  def buy_payment_amount(pay_asset_id)
    case pay_asset_id
    when asset_id
      price
    else
      begin
        Foxswap.api.pre_order(
          pay_asset_id: pay_asset_id,
          fill_asset_id: asset_id,
          amount: (price * 1.01).round(8).to_r.to_f
        )['data']['funds']
      rescue StandardError
        nil
      end
    end
  end

  def buy_payment_memo
    Base64.urlsafe_encode64({ t: 'BUY', a: uuid }.to_json)
  end

  def reward_payment_memo
    Base64.urlsafe_encode64({ t: 'REWARD', a: uuid }.to_json)
  end

  def related_articles
    @related_articles ||= citers.presence || tag_related_articles.presence || author_other_articles
  end

  def tag_related_articles
    @tag_related_articles ||=
      Article
      .includes(:tags)
      .published
      .where.not(id: id)
      .where(tags: { name: tag_names })
      .order(published_at: :desc)
      .limit(5)
  end

  def author_other_articles
    @author_other_articles ||=
      author
      .articles
      .published
      .where.not(id: id)
      .order(published_at: :desc)
      .limit(5)
  end

  def attach_images_from_content_async
    ArticleAttachImagesFromContentWorker.perform_async uuid
  end

  def attach_images_from_content
    signed_ids = []
    content.scan(%r{blob://\S+}).each do |url|
      key = url.gsub('blob://', '').split('/').first
      blob = ActiveStorage::Blob.find_by key: key
      next if blob.blank?

      signed_ids.push blob.signed_id
    end

    images.attach signed_ids
  end

  def update_attached_image_url_in_content
    content.scan(%r{\(/rails/active_storage/blobs/.+\)}).each_with_index do |url, index|
      image = ActiveStorage::Blob.find_signed url.split('/')[4]
      image ||= images.blobs.order(created_at: :asc)&.[](index)
      next if image.blank?

      content.gsub! url, "(#{image.url})"
    end

    save
  end

  def detect_locale
    if plain_text.to_s.size > 140
      locales = [CLD.detect_language(intro)[:code], CLD.detect_language(plain_text)[:code]].uniq

      if locales.size == 1
        update locale: locales.first
      else
        update locale: locales.reject(&->(l) { l == 'en' }).last
      end
    else
      update locale: 'un'
    end
  end

  def detect_locale_async
    ArticleDetectLocaleWorker.perform_async uuid
  end

  def mixpay_supported?
    asset_id.in? (Mixpay.api.settlement_asset_ids + Mixpay.api.quote_asset_ids).uniq
  end

  private

  def setup_attributes
    return unless new_record?

    assign_attributes(
      uuid: SecureRandom.uuid
    )

    self.asset_id = Currency::BTC_ASSET_ID
    self.price = currency.minimal_price_amount
  end

  def set_default_intro
    self.intro = default_intro if intro.blank?
  end

  def can_not_change_currency_after_published
    return if published_at.blank?

    errors.add(:asset_id, 'cannot change') if asset_id_changed?
  end

  def ensure_price_not_too_low
    return unless price_changed? || asset_id_changed?

    errors.add(:price, '< $0.1') if price.positive? && price < currency.minimal_price_amount
  end

  def ensure_revenue_ratios_sum_to_one
    errors.add(:author_revenue_ratio, ' incorrect') unless (revenue_ratios_sum - 1.0).abs < Float::EPSILON
  end

  def ensure_references_ratios_correct
    errors.add(:references_revenue_ratio, ' incorrect') unless references_revenue_ratio.to_d == article_references.reject(&:_destroy).sum(&:revenue_ratio).to_d
  end
end
