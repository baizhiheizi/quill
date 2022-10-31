# frozen_string_literal: true

# == Schema Information
#
# Table name: nft_collections
#
#  id         :bigint           not null, primary key
#  raw        :jsonb
#  uuid       :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  creator_id :uuid
#
# Indexes
#
#  index_nft_collections_on_uuid  (uuid) UNIQUE
#
class NftCollection < ApplicationRecord
  store_accessor :raw, %i[name description symbol icon]

  belongs_to :collection, primary_key: :uuid, foreign_key: :uuid, inverse_of: :nft_collection, optional: true
  has_many :collectibles, dependent: :restrict_with_exception

  before_validation :setup_default_attributes

  validates :uuid, presence: true, uniqueness: true
  validates :raw, presence: true

  def sync!
    raw = Trident.api.collection uuid
    return if raw.blank?

    update! raw: raw
  end

  def trident_url
    Addressable::URI.new(
      scheme: 'https',
      host: 'thetrident.one',
      path: "collections/#{uuid}"
    ).to_s
  end

  def icon_url
    icon['url'] || format('https://api.multiavatar.com/%<uuid>s.png', uuid: uuid)
  end

  private

  def setup_default_attributes
    return if uuid.present? && raw.present?

    r =
      begin
        Trident.api.collection(uuid)
      rescue TridentAssistant::Client::RequestError
        {}
      end

    return if r['id'].blank?

    assign_attributes(
      raw: r,
      uuid: r['id']
    )
  end
end
