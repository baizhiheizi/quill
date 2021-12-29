# frozen_string_literal: true

# == Schema Information
#
# Table name: bonuses
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  title       :string
#  description :text
#  state       :string
#  asset_id    :string
#  amount      :decimal(, )
#  trace_id    :uuid
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
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
