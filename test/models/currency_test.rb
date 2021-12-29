# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
#
#  id         :integer          not null, primary key
#  asset_id   :uuid
#  raw        :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_currencies_on_asset_id  (asset_id) UNIQUE
#

require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
