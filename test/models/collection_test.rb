# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id                     :bigint           not null, primary key
#  description            :text
#  name                   :string
#  order_count            :integer          default(0)
#  platform_revenue_ratio :float            default(0.1)
#  price                  :decimal(, )
#  revenue_ratio          :float            default(0.2)
#  state                  :string
#  symbol                 :string
#  uuid                   :uuid
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  asset_id               :uuid
#  author_id              :uuid
#
# Indexes
#
#  index_collections_on_author_id  (author_id)
#  index_collections_on_uuid       (uuid) UNIQUE
#
require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
