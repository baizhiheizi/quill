# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id                     :bigint           not null, primary key
#  description            :text
#  name                   :string
#  orders_count           :integer          default(0)
#  platform_revenue_ratio :float            default(0.1)
#  price                  :decimal(, )
#  revenue_ratio          :float            default(0.2)
#  state                  :string
#  symbol                 :string
#  uuid                   :uuid
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  asset_id               :uuid
#  author_id              :uuid
#
# Indexes
#
#  index_collections_on_author_id  (author_id)
#  index_collections_on_uuid       (uuid) UNIQUE
#
class Collection < ApplicationRecord
  SUPPORTED_ASSETS = Settings.supported_assets || [Currency::BTC_ASSET_ID]
  MINIMUM_PRICE_USD = 6.99
  DEFAULT_SPLIT = '0.1'

  include AASM
  include Collections::Payable

  has_one_attached :cover

  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: false
  belongs_to :author, class_name: 'User', primary_key: :mixin_uuid

  has_one :nft_collection, primary_key: :uuid, foreign_key: :uuid, dependent: :restrict_with_exception, inverse_of: :collection

  has_many :collectings, dependent: :restrict_with_exception
  has_many :collectibles, primary_key: :uuid, dependent: :restrict_with_exception
  has_many :validatable_collections, through: :collectings, source: :nft_collection
  has_many :articles, primary_key: :uuid, dependent: :restrict_with_exception
  has_many :orders, as: :item, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :symbol, presence: true
  validates :description, presence: true
  validates :asset_id, inclusion: { in: SUPPORTED_ASSETS }, if: :new_record?
  validates :price, presence: true, numericality: { greater_than: 0.0 }
  validates :revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 0.5 }

  validate :ensure_price_not_too_low

  delegate :trident_url, to: :nft_collection

  aasm column: :state do
    state :drafted, initial: true
    state :listed
    state :hidden

    event :list, guard: :nft_collection_present? do
      transitions from: :drafted, to: :listed
      transitions from: :hidden, to: :listed
    end

    event :hide do
      transitions from: :listed, to: :hidden
    end
  end

  delegate :present?, to: :nft_collection, prefix: true

  def list_on_trident!
    NftCollection.find_or_create_by uuid: uuid if uuid.present?
    return if nft_collection_present?

    generate_cover if cover_url.blank?

    r = Trident.api.create_collection(
      name: name,
      symbol: symbol,
      description: description,
      split: DEFAULT_SPLIT,
      external_url: 'https://quill.im',
      icon_url: cover_url
    )
    update! uuid: r['id'] if r['id'].present?

    ActiveRecord::Base.transaction do
      NftCollection.create! uuid: r['id'], raw: r
      reload.list!
    end
  end

  def may_destroy?
    !listed_on_trident?
  end

  def listed_on_trident?
    uuid.present?
  end

  def price_tag
    "#{format('%.8f', price).gsub(/0+\z/, '0')} #{currency.symbol}"
  end

  def price_usd
    (currency.price_usd.to_f * price).to_f.round(4)
  end

  def cover_url
    return unless cover.attached?

    [Settings.storage.endpoint, cover.key].join('/')
  end

  def generated_cover_url
    grover_collection_cover_url id, token: Rails.application.credentials.dig(:grover, :token), format: :png
  end

  def generate_cover
    file = URI.parse(generated_cover_url).open
    cover.attach io: file, filename: "#{name}_cover"
  end

  def generated_collectible_media_url(identifier)
    grover_collection_collectible_url(
      id,
      identifier: identifier,
      token: Rails.application.credentials.dig(:grover, :token),
      format: :png
    )
  end

  def qrcode_base64
    ['data:image/png;base64, ',
     Base64.encode64(
       RQRCode::QRCode.new(
         collection_url(uuid)
       ).as_png(border_modules: 0).to_s
     )].join
  end

  def mintable_order_from(user = nil)
    return if user.blank?

    order = orders.find_by buyer: user
    return if order.blank?
    return if order.collectible.present?

    order
  end

  def authorized?(user = nil)
    return if user.blank?
    return true if author == user

    order = orders.find_by buyer: user
    return true if order.present? && (order.collectible.blank? || order.collectible.pending?)

    ((validatable_collections.pluck(:uuid) + [uuid]) & user.owning_collection_ids).present?
  end

  private

  def lock_attributes_once_listed
    return if uuid.blank?

    errors.add(:name, 'cannot change') if name_changed?
    errors.add(:symbol, 'cannot change') if symbol_changed?
    errors.add(:revenue_ratio, 'cannot change') if revenue_ratio_changed?
  end

  def ensure_price_not_too_low
    return unless price_changed? || asset_id_changed?

    errors.add(:price, "< $#{MINIMUM_PRICE_USD}") if price.to_f.positive? && price < currency.minimal_price_amount(MINIMUM_PRICE_USD)
  end
end
