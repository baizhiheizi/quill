# frozen_string_literal: true

# == Schema Information
#
# Table name: nft_collections
# Database name: primary
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

  validates :uuid, presence: true, uniqueness: true
  validates :raw, presence: true

  def icon_url
    icon&.dig("url") || User.default_avatar_url
  end
end
