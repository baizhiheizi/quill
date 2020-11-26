# frozen_string_literal: true

# == Schema Information
#
# Table name: bonuses
#
#  id          :bigint           not null, primary key
#  amount      :decimal(, )
#  description :text
#  state       :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  asset_id    :string
#  trace_id    :uuid
#  user_id     :bigint
#
# Indexes
#
#  index_bonuses_on_trace_id  (trace_id) UNIQUE
#  index_bonuses_on_user_id   (user_id)
#
require 'test_helper'

class BonusTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
