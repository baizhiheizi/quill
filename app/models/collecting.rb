# frozen_string_literal: true

# == Schema Information
#
# Table name: collectings
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  collection_id     :bigint
#  nft_collection_id :bigint
#
# Indexes
#
#  index_collectings_on_collection_id_and_nft_collection_id  (collection_id,nft_collection_id) UNIQUE
#
class Collecting < ApplicationRecord
  belongs_to :collection
  belongs_to :nft_collection
end
