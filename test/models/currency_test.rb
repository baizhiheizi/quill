# frozen_string_literal: true

# == Schema Information
#
# Table name: currencies
#
#  id                   :bigint           not null, primary key
#  mvm_contract_address :string
#  price_btc            :decimal(, )
#  price_usd            :decimal(, )
#  raw                  :jsonb
#  symbol               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  asset_id             :uuid
#  chain_id             :uuid
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
