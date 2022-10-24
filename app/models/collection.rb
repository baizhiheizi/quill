# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id            :bigint           not null, primary key
#  description   :text
#  name          :string
#  price         :decimal(, )
#  revenue_ratio :uuid
#  state         :string
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
  belongs_to :author, class_name: 'User', primary_key: :mixin_uuid

  has_one :nft_collection, dependent: :restrict_with_exception
  has_many :collectings, dependent: :restrict_with_exception
  has_many :validatable_collections, through: :collectings, source: :nft_collection

  def to_param
    uuid
  end
end
