# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id            :bigint           not null, primary key
#  description   :text
#  name          :string
#  price         :decimal(, )
#  revenue_ratio :float            default(0.2)
#  state         :string
#  symbol        :string
#  uuid          :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  asset_id      :uuid
#  author_id     :uuid
#
# Indexes
#
#  index_collections_on_author_id  (author_id)
#  index_collections_on_uuid       (uuid) UNIQUE
#
class Collection < ApplicationRecord
  SUPPORTED_ASSETS = Settings.supported_assets || [Currency::BTC_ASSET_ID]

  include AASM

  has_one_attached :cover

  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id, inverse_of: false
  belongs_to :author, class_name: 'User', primary_key: :mixin_uuid

  has_one :nft_collection, primary_key: :uuid, foreign_key: :uuid, dependent: :restrict_with_exception, inverse_of: :collection

  has_many :collectings, dependent: :restrict_with_exception
  has_many :validatable_collections, through: :collectings, source: :nft_collection

  validates :name, presence: true
  validates :symbol, presence: true
  validates :description, presence: true
  validates :asset_id, inclusion: { in: SUPPORTED_ASSETS }, if: :new_record?
  validates :price, presence: true, numericality: { greater_than: 0.0 }
  validates :revenue_ratio, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 0.5 }

  validate :ensure_price_not_too_low

  aasm column: :state do
    state :drafted, initial: true
    state :listed
    state :hidden

    event :list do
      transitions from: :drafted, to: :listed
      transitions from: :hidden, to: :listed
    end

    event :hide do
      transitions from: :listed, to: :hidden
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

  def generate_cover
    file = URI.parse(grover_collection_cover_url(id, format: :png)).open
    cover.attach io: file, filename: "#{name}_cover"
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

    errors.add(:price, '< $6.99') if price.to_f.positive? && price < currency.minimal_price_amount(6.99)
  end
end
