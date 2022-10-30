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
require 'test_helper'

class CollectibleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
