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
require 'test_helper'

class CollectingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
