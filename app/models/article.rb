# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
# Database name: primary
#
#  id                                  :bigint           not null, primary key
#  author_revenue_ratio                :float            default(0.5)
#  collection_revenue_ratio            :float            default(0.0)
#  commenting_subscribers_count        :integer          default(0)
#  comments_count                      :integer          default(0), not null
#  downvotes_count                     :integer          default(0)
#  free_content_ratio                  :float            default(0.1)
#  intro                               :string
#  legacy_markdown_content             :text
#  locale                              :string
#  lock_version                        :integer          default(0), not null
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
#  collection_id                       :uuid
#
# Indexes
#
#  index_articles_on_asset_id       (asset_id)
#  index_articles_on_author_id      (author_id)
#  index_articles_on_collection_id  (collection_id)
#  index_articles_on_intro_trgm     (intro) USING gin
#  index_articles_on_title_trgm     (title) USING gin
#  index_articles_on_uuid           (uuid) UNIQUE
#

class Article < ApplicationRecord
  is_impressionable

  SUPPORTED_ASSETS = Settings.supported_assets || [ Currency::BTC_ASSET_ID ]
  AUTHOR_REVENUE_RATIO_DEFAULT = 0.5
  READERS_REVENUE_RATIO_DEFAULT = 0.4
  PLATFORM_REVENUE_RATIO_DEFAULT = 0.1

  include AASM
  include Articles::ContentPreview
  include Articles::PosterGenerator
  include Articles::Purchasable
  include RichTextContent

  belongs_to :author, class_name: "User", inverse_of: :articles, counter_cache: true
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :articles
  belongs_to :collection, primary_key: :uuid, inverse_of: :articles, optional: true

  has_many :orders, as: :item, dependent: :restrict_with_error
  has_many :pre_orders, as: :item, dependent: :restrict_with_error
  has_many :buy_orders, -> { where(order_type: :buy_article) }, class_name: "Order", as: :item, dependent: :restrict_with_error, inverse_of: false
  has_many :reward_orders, -> { where(order_type: :reward_article) }, class_name: "Order", as: :item, dependent: :restrict_with_error, inverse_of: false
  has_many :cite_orders, -> { where(order_type: :cite_article) }, class_name: "Order", as: :item, dependent: :restrict_with_error, inverse_of: false

  has_many :readers, -> { distinct }, through: :orders, source: :buyer
  has_many :buyers, -> { distinct }, through: :buy_orders, source: :buyer
  has_many :rewarders, -> { distinct }, through: :reward_orders, source: :buyer

  has_many :transfers, through: :orders, dependent: :restrict_with_error
  has_many :author_transfers, -> { where(transfer_type: :author_revenue) }, through: :orders, source: :transfers, dependent: :restrict_with_error
  has_many :reader_transfers, -> { where(transfer_type: :reader_revenue) }, through: :orders, source: :transfers, dependent: :restrict_with_error

  has_many :comments, as: :commentable, dependent: :restrict_with_error

  has_many :taggings, dependent: :nullify
  has_many :tags, through: :taggings, dependent: :restrict_with_error

  has_many :snapshots, class_name: "ArticleSnapshot", primary_key: :uuid, foreign_key: :article_uuid, inverse_of: :article, dependent: :destroy

  has_many :article_references, class_name: "CiterReference", as: :citer, dependent: :destroy
  has_many :references, through: :article_references, source: :reference, source_type: "Article"
  has_many :article_citers, class_name: "CiterReference", as: :reference, dependent: :restrict_with_error
  has_many :citers, through: :article_citers, source: :citer, source_type: "Article"

  has_many_attached :images
  has_one_attached :poster
  has_one_attached :cover

  accepts_nested_attributes_for :article_references, reject_if: proc { |attributes| attributes["reference_id"].blank? || attributes["revenue_ratio"].blank? }, allow_destroy: true

  has_one :wallet, class_name: "MixinNetworkUser", as: :owner, dependent: :nullify

  validates :asset_id, inclusion: { in: SUPPORTED_ASSETS }, if: :new_record?
  validates :uuid, presence: true, uniqueness: true
  validates :title, length: { maximum: 64 }
  validates :intro, length: { maximum: 140 }
  validates :title, presence: true, unless: :drafted?
  validates :intro, presence: true, unless: :drafted?
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validates :platform_revenue_ratio, presence: true, numericality: { equal_to: 0.1 }
  validates :readers_revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.1 }
  validates :author_revenue_ratio, presence: true, numericality: { less_than_or_equal_to: 0.8 }
  validates :references_revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validates :free_content_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 0.9 }
  validate :ensure_price_not_too_low
  validate :ensure_references_ratios_correct
  validate :ensure_revenue_ratios_sum_to_one
  validate :cannot_edit_frozen_attributes_once_published

  before_validation :setup_attributes, on: :create
  before_validation :set_defaults
  after_save do
    generate_snapshot if should_generate_snapshot?
    detect_locale_async if content_changed_since_save?
  end

  # Eager-load chain consumed by the public article index / search results
  # (`ArticleSearchService` and `ArticlesController#index`) AND by the
  # dashboard / users articles tabs (which now use this scope too — see
  # `Dashboard::ArticlesController#index` and `Users::ArticlesController#index`):
  #   - `:currency`   → `article.price_tag`
  #   - `:tags`       → tag chips
  #   - `cover_attachment: :blob` → `article.cover.attached?` +
  #     `article.cover.key` via `article_card_image_url(article)` in
  #     `articles/_card.html.erb`. Without this nested preload each row
  #     with a cover fires 1 extra SELECT to resolve the blob.
  #   - `:author`     → author byline + `user_path(article.author)` +
  #     author avatar chain consumed by `shared/_avatar` in
  #     `articles/_card.html.erb`. Without the nested
  #     `User::AVATAR_PRELOADS` chain each row would fire 4-5 extra
  #     SELECTs (authorization + avatar_attachment + blob + variant_records
  #     + image_attachment blob). For the default pagy page of 50 articles
  #     that's 200-250 extra SELECTs per feed render — see the comment on
  #     `User::AVATAR_PRELOADS` for the breakdown.
  # The show page uses a heavier chain (see `with_show_associations`) —
  # it adds `:article_references`, the `collection` (with its own cover),
  # and an explicit `cover_attachment: :blob` (Rails merges the duplicate
  # hash key from the base scope into a single preload).
  scope :with_associations, -> {
    includes(:currency, :tags, cover_attachment: :blob, author: User::AVATAR_PRELOADS)
  }

  # Eager-load chain consumed by `ArticlesController#show` →
  # `articles/show.html.erb`. Includes the base `with_associations`
  # shape plus:
  #   - `:collection` (+ its `cover_attachment.blob`) → the "published in
  #     <collection>" pill in `_header.html.erb` and the collection card
  #     in `_widgets.html.erb`. `Collection#cover_url` walks the
  #     ActiveStorage chain, so the attachment and its blob must be
  #     loaded together.
  #   - `cover_attachment: :blob` → `article.cover.attached?` +
  #     `cover.metadata` + `remote_image_tag article.cover_url` in
  #     `_header.html.erb`. Without this preload the show page fires
  #     1 extra SELECT to load the cover blob on every visit.
  #   - `:article_references` → the references card in `_widgets.html.erb`.
  scope :with_show_associations, -> {
    with_associations.includes(
      :article_references,
      { cover_attachment: :blob },
      { collection: { cover_attachment: :blob } }
    )
  }
  scope :without_blocked, -> { where.not(state: :blocked) }
  scope :without_free, -> { where("price > ?", 0) }
  scope :only_free, -> { where(price: 0.0) }
  scope :only_drafted, -> { where(state: :drafted) }
  scope :only_published, -> { where(state: :published) }
  scope :without_drafted, -> { where.not(state: :drafted) }
  scope :order_by_revenue_usd, -> { order(revenue_usd: :desc) }
  # Default feed sort. Uses LEFT JOIN so articles with no orders are
  # still eligible (popularity falls back to 0 via COALESCE) and so
  # subsequent callers can add their own joins without breaking the
  # existing ones.
  scope :order_by_popularity, lambda {
    left_joins(:orders)
      .group(:id)
      .select(
        <<~SQL.squish
          articles.*,#{' '}
          (((COALESCE(SUM(orders.value_usd), 0) * 10 + (articles.upvotes_count - articles.downvotes_count) * COALESCE(AVG(orders.value_usd), 0) * 20 + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.published_at)) / 3600)::integer + 1), 2))) AS popularity
        SQL
      )
      .order("popularity DESC, published_at DESC")
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
    return if author.blocked?

    ArticlePublishedNotifier
      .with(record: self, article: self)
      .deliver(
        User
          .where(id: author.subscribed_user_ids_relation)
          .where.not(id: author.blocked_user_ids_relation)
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

  def wallet_id
    @wallet_id = wallet&.uuid
  end

  def author_revenue_usd
    @author_revenue_usd ||= author_transfers.joins(:currency).sum("amount * currencies.price_usd")
  end

  def reader_revenue_usd
    @reader_revenue_usd ||= reader_transfers.joins(:currency).sum("amount * currencies.price_usd")
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
    sampled_buyer_ids = orders.select(:buyer_id).group(:buyer_id).order(Arel.sql("RANDOM()")).limit(limit)

    User.where(id: sampled_buyer_ids)
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
    Articles::NotifyForFirstPublishedJob.perform_later id
  end

  def do_first_publish
    return unless published?
    return if published_at.present?

    touch_published_at
    notify_for_first_published_async
    subscribe_comments_for_author
  end

  def generate_snapshot
    snapshots.create raw: as_json
  end

  def should_generate_snapshot?
    return false if drafted?

    content_changed_since_save? || saved_change_to_title? || saved_change_to_intro? || saved_change_to_published_at?
  end

  def revenue_ratios_sum
    [
      platform_revenue_ratio,
      readers_revenue_ratio,
      author_revenue_ratio,
      collection_revenue_ratio,
      references_revenue_ratio
    ].sum
  end

  def to_param
    uuid
  end

  def ensure_content_valid
    title.present? && content.present?
  end

  def related_articles
    @related_articles ||= citers.presence || tag_related_articles.presence || author_other_articles
  end

  def tag_related_articles
    @tag_related_articles ||=
      Article
      .includes(:tags)
      .published
      .where.not(id:)
      .where(tags: { name: tag_names })
      .order(published_at: :desc)
      .limit(5)
  end

  def author_other_articles
    @author_other_articles ||=
      author
      .articles
      .published
      .where.not(id:)
      .order(published_at: :desc)
      .limit(5)
  end

  def detected_locale
    if plain_text.to_s.size > 140
      locales = [ CLD.detect_language(intro)[:code], CLD.detect_language(plain_text)[:code] ].uniq

      if locales.size == 1
        locales.first.split("-").first
      else
        locales.reject(&->(l) { l == "en" }).last.split("-").first
      end
    elsif author.present?
      author.locale.split("-").first
    end
  end

  def detect_locale
    update locale: detected_locale
  end

  def detect_locale_async
    Articles::DetectLocaleJob.perform_later uuid
  end

  def payment_trace_id(user)
    return if user.blank?

    # generate a unique trace ID for paying
    # avoid duplicate payment
    candidate = QuillBot.api.unique_uuid(uuid, user.mixin_uuid)
    loop do
      break unless Payment.exists?(trace_id: candidate) || PreOrder.exists?(trace_id: candidate, state: %i[paid expired])

      candidate = QuillBot.api.unique_uuid(uuid, candidate)
    end

    candidate
  end

  def mixpay_supported?
    return true if free?

    asset_id.in?(Mixpay.api.settlement_asset_ids)
  rescue Mixpay::Errors::Error
    false
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title intro content uuid id state locale published_at] + _ransackers.keys
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[author tags currency]
  end

  private

  def drafted?
    state == "drafted"
  end

  def validate_rich_text_content_presence?
    !drafted?
  end

  def setup_attributes
    return unless new_record?

    self.uuid = SecureRandom.uuid if uuid.blank?
    self.asset_id = Currency::BTC_ASSET_ID
    self.price = currency.minimal_price_amount if price.blank?
  end

  def set_defaults
    self.intro = default_intro if intro.blank?
    self.intro = intro.truncate(140)
    self.locale = detected_locale

    return if published_at.present?

    self.collection_revenue_ratio =
      if collection.present?
        collection.revenue_ratio
      else
        0
      end
  end

  def cannot_edit_frozen_attributes_once_published
    return if published_at.blank?

    errors.add(:asset_id, "cannot change") if asset_id_changed?
    errors.add(:collection_id, "cannot change") if collection_revenue_ratio.positive? && collection_id_changed?
    errors.add(:collection_revenue_ratio, "cannot change") if collection_revenue_ratio_changed?
  end

  def ensure_price_not_too_low
    return unless price_changed? || asset_id_changed?

    errors.add(:price, "< $0.1") if price.positive? && price < currency.minimal_price_amount
  end

  def ensure_revenue_ratios_sum_to_one
    errors.add(:author_revenue_ratio, " incorrect") unless (revenue_ratios_sum - 1.0).abs < Float::EPSILON
  end

  def ensure_references_ratios_correct
    errors.add(:references_revenue_ratio, " incorrect") unless references_revenue_ratio.to_d == article_references.reject(&:_destroy).sum(&:revenue_ratio).to_d
  end
end
