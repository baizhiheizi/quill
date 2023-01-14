# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                                  :bigint           not null, primary key
#  author_revenue_ratio                :float            default(0.5)
#  collection_revenue_ratio            :float            default(0.0)
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
#  collection_id                       :uuid
#
# Indexes
#
#  index_articles_on_asset_id       (asset_id)
#  index_articles_on_author_id      (author_id)
#  index_articles_on_collection_id  (collection_id)
#  index_articles_on_uuid           (uuid) UNIQUE
#

class Article < ApplicationRecord
  second_level_cache expires_in: 1.week
  is_impressionable

  SUPPORTED_ASSETS = Settings.supported_assets || [Currency::BTC_ASSET_ID]
  AUTHOR_REVENUE_RATIO_DEFAULT = 0.5
  READERS_REVENUE_RATIO_DEFAULT = 0.4
  PLATFORM_REVENUE_RATIO_DEFAULT = 0.1

  include AASM
  include Articles::Arweavable
  include Articles::Payable

  belongs_to :author, class_name: 'User', inverse_of: :articles
  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: :articles
  belongs_to :collection, primary_key: :uuid, inverse_of: :articles, optional: true

  has_many :orders, as: :item, dependent: :restrict_with_error
  has_many :pre_orders, as: :item, dependent: :restrict_with_error
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

  has_many :arweave_transactions, primary_key: :uuid, foreign_key: :article_uuid, dependent: :restrict_with_exception, inverse_of: :article

  has_many_attached :images
  has_one_attached :poster
  has_one_attached :cover

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
  validate :cannot_edit_frozen_attributes_once_published

  before_validation :setup_attributes, on: :create
  before_validation :set_defaults
  after_save do
    generate_snapshot if should_generate_snapshot?
    if saved_change_to_content?
      attach_images_from_content_async
      detect_locale_async
    end
  end

  delegate :swappable?, to: :currency

  default_scope -> { includes(:currency, :tags, :author) }
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
          (((SUM(orders.value_usd) * 10 + (articles.upvotes_count - articles.downvotes_count) * AVG(orders.value_usd) * 20 + articles.comments_count) / POW(((EXTRACT(EPOCH FROM (now()-articles.published_at)) / 3600)::integer + 1), 2))) AS popularity
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

    orders.where(order_type: :buy_article).find_by(buyer: user).present? || collection&.authorized?(user)
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
    @plain_text ||= ActionController::Base.helpers.strip_tags(MarkdownRenderService.call(content&.strip || ''))
  end

  def words_count
    @words_count ||= plain_text.scan(/[a-zA-Z]+|\S/).size
  end

  def partial_content
    return if words_count < 300

    plain_text.truncate((words_count * 0.1).to_i)
  end

  def partial_content_as_html
    @partial_content_as_html ||= extract_html(content_as_html, (words_count * 0.1).to_i)
  end

  def extract_html(text, length)
    count = 0
    html = ''

    Nokogiri::HTML.fragment(text).children.each do |child|
      if (length - count - child.text.size).positive?
        count += child.text.size
        html += child.to_s
      elsif child.to_s.empty?
        html += child.to_s
      elsif (length - count).positive?
        case child
        when Nokogiri::XML::NodeSet
          child.inner_html = extract_html(child.to_s, length - count)
        when Nokogiri::XML::Text
          child.content = child.text.truncate(length - count)
        end

        count = length
        html += child.to_s
      end
    end

    html
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
    Articles::NotifyForFirstPublishedJob.perform_async id
  end

  def create_wallet_async
    Articles::CreateWalletJob.perform_async id
  end

  def do_first_publish
    return unless published?
    return if published_at.present?

    touch_published_at
    notify_for_first_published_async
    subscribe_comments_for_author
    upload_to_arweave_async
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
      collection_revenue_ratio,
      references_revenue_ratio
    ].sum
  end

  def to_param
    uuid
  end

  def content_as_html
    MarkdownRenderService.call content.to_s.strip, type: :full
  end

  def default_intro
    plain_text.truncate(140)
  end

  def upvote_ratio
    return if upvotes_count.zero? && downvotes_count.zero?

    "#{format('%.0f', upvotes_count.to_f * 100 / (upvotes_count + downvotes_count))}%"
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

  def attach_images_from_content
    update content: blob_parsed_content
  end

  def attach_images_from_content_async
    Articles::AttachImagesFromContentJob.perform_async uuid
  end

  def blob_parsed_content
    urls = content.scan(%r{\(blob://.+\)})
    temp_content = content.dup
    urls.each do |url|
      key = url.gsub(%r{\(blob://|\)}, '').split('/').first
      blob = ActiveStorage::Blob.find_by key: key
      next if blob.blank?

      temp_content = temp_content.gsub(url, "(#{blob.url})") if images.attach(blob.signed_id)
    end

    temp_content
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

  def detected_locale
    if plain_text.to_s.size > 140
      locales = [CLD.detect_language(intro)[:code], CLD.detect_language(plain_text)[:code]].uniq

      if locales.size == 1
        locales.first.split('-').first
      else
        locales.reject(&->(l) { l == 'en' }).last.split('-').first
      end
    elsif author.present?
      author.locale.split('-').first
    end
  end

  def detect_locale
    update locale: detected_locale
  end

  def detect_locale_async
    Articles::DetectLocaleJob.perform_async uuid
  end

  def thumb_url
    @thumb_url ||=
      if cover.attached?
        cover_url
      elsif free?
        Nokogiri::HTML
          .fragment(content_as_html)
          .css('img')
          .map(&->(img) { img.attr('src') })
          .find(&->(url) { URI::DEFAULT_PARSER.make_regexp.match?(url) })
      end
  end

  def cover_url
    [Settings.storage.endpoint, cover.key].join('/') if cover.attached?
  end

  def poster_url
    if poster.attached?
      [Settings.storage.endpoint, poster.key].join('/')
    else
      generate_poster_async
      nil
    end
  end

  def generated_poster_url
    grover_article_poster_url uuid, token: Rails.application.credentials.dig(:grover, :token), format: :png
  end

  def generate_poster
    file = URI.parse(generated_poster_url).open
    poster.attach io: file, filename: "#{title}_poster"
  end

  def generate_poster_async
    Articles::GeneratePosterJob.perform_async id
  end

  def qrcode_base64
    ['data:image/png;base64, ',
     Base64.encode64(
       RQRCode::QRCode.new(
         user_article_url(author, self)
       ).as_png(border_modules: 0).to_s
     )].join
  end

  def fix_img_tag_in_content
    content.gsub(/!\[[^\]]*\]\((.*?)\s*("(?:.*[^"])")?\s*\)(\\n)*/) { |m| "#{m.strip}\n" }
  end

  private

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
    self.content = blob_parsed_content if content_changed?

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

    errors.add(:asset_id, 'cannot change') if asset_id_changed?
    errors.add(:collection_id, 'cannot change') if collection_revenue_ratio.positive? && collection_id_changed?
    errors.add(:collection_revenue_ratio, 'cannot change') if collection_revenue_ratio_changed?
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
