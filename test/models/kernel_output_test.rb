# frozen_string_literal: true

# == Schema Information
#
# Table name: kernel_outputs
#
#  id         :bigint           not null, primary key
#  amount     :decimal(, )
#  raw        :json
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#
# Indexes
#
#  index_kernel_outputs_on_asset_id  (asset_id)
#
require 'test_helper'

class KernelOutputTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
