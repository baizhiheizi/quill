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
require 'test_helper'

class NftCollectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
