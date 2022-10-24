# frozen_string_literal: true

# == Schema Information
#
# Table name: collectibles
#
#  id            :bigint           not null, primary key
#  identifier    :string
#  metadata      :jsonb
#  metahash      :string
#  name          :string
#  state         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :uuid
#  token_id      :uuid
#
# Indexes
#
#  index_collectibles_on_collection_id_and_identifier  (collection_id,identifier) UNIQUE
#  index_collectibles_on_metahash                      (metahash) UNIQUE
#  index_collectibles_on_token_id                      (token_id) UNIQUE
#
class Collectible < ApplicationRecord
  include AASM

  belongs_to :collection, primary_key: :uuid, optional: true
  belongs_to :nft_collection, primary_key: :uuid, foreign_key: :collection_id, optional: true, inverse_of: :collectibles
  has_many :non_fungible_outputs, primary_key: :token_id, foreign_key: :token_id, dependent: :restrict_with_exception, inverse_of: :collectible

  before_validation :setup_default_attributes, on: :create

  validates :identifier, presence: true
  validates :name, presence: true
  validates :metahash, presence: true

  aasm column: :state do
    state :pending, initial: true
    state :minted

    event :mint do
      transitions from: :pending, to: :minted
    end
  end

  def collection_id_valid?
    collection_id.present? && collection_id != '00000000-0000-0000-0000-000000000000'
  end

  def trident_url
    Addressable::URI.new(
      scheme: 'https',
      host: 'thetrident.one',
      path: "collectibles/#{metahash}"
    ).to_s
  end

  private

  def setup_default_attributes
    return if token_id.blank?

    r = QuillBot.api.collectible token_id
    group =
      if r['group'].present?
        begin
          MixinBot::Utils::UUID.new(hex: r['group']).unpacked
        rescue MixinBot::InvalidUuidFormatError
          ''
        end
      end

    assign_attributes(
      identifier: r['token'],
      collection_id: group,
      metahash: r['meta']['hash'],
      name: r['meta']['name'],
      metadata: r['meta']
    )

    self.nft_collection = NftCollection.find_or_create_by(uuid: collection_id) if collection_id_valid?
  end
end
