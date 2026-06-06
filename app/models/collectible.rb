# frozen_string_literal: true

# == Schema Information
#
# Table name: collectibles
# Database name: primary
#
#  id            :bigint           not null, primary key
#  identifier    :string
#  metadata      :jsonb
#  metahash      :string
#  name          :string
#  source_type   :string
#  state         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :uuid
#  source_id     :bigint
#  token_id      :uuid
#
# Indexes
#
#  index_collectibles_on_collection_id_and_identifier  (collection_id,identifier) UNIQUE
#  index_collectibles_on_metahash                      (metahash) UNIQUE
#  index_collectibles_on_source_type_and_source_id     (source_type,source_id) UNIQUE
#  index_collectibles_on_token_id                      (token_id) UNIQUE
#
class Collectible < ApplicationRecord
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :collection, primary_key: :uuid, optional: true
  belongs_to :nft_collection, primary_key: :uuid, foreign_key: :collection_id, optional: true, inverse_of: :collectibles

  has_many :non_fungible_outputs, primary_key: :token_id, foreign_key: :token_id, dependent: :restrict_with_exception, inverse_of: :collectible
  has_many :transfers, as: :source, dependent: :restrict_with_exception

  has_one_attached :media

  before_validation :setup_default_attributes, on: :create

  validates :identifier, presence: true
  validates :name, presence: true
  validates :metahash, presence: true
  validates :collection_id, presence: true

  def media_url
    if media.attached?
      [ Settings.storage.endpoint, media.key ].join("/")
    else
      metadata&.[]("media_url")
    end
  end

  def collection_id_valid?
    collection_id != "00000000-0000-0000-0000-000000000000"
  end

  private

  def setup_default_attributes
    return if token_id.blank?

    r = QuillBot.api.collectible token_id
    group =
      if r["group"].present?
        begin
          MixinBot::UUID.new(hex: r["group"]).unpacked
        rescue MixinBot::InvalidUuidFormatError
          "00000000-0000-0000-0000-000000000000"
        end
      end

    assign_attributes(
      identifier: r["token"],
      collection_id: group,
      metahash: r["meta"]["hash"],
      name: r["meta"]["name"],
      metadata: r["meta"]
    )

    self.nft_collection = NftCollection.find_or_create_by(uuid: collection_id) if collection_id_valid?
  end
end
