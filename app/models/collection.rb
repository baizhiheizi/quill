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

  belongs_to :currency, primary_key: :asset_id, foreign_key: :asset_id
  belongs_to :author, class_name: 'User', primary_key: :mixin_uuid

  has_one :nft_collection, dependent: :restrict_with_exception
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

  def to_param
    uuid
  end

  private

  def ensure_price_not_too_low
    return unless price_changed? || asset_id_changed?

    errors.add(:price, '< $6.99') if price.to_f.positive? && price < currency.minimal_price_amount(6.99)
  end
end
