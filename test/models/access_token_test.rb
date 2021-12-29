# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  value        :uuid
#  memo         :string
#  last_request :jsonb
#  deleted_at   :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_access_tokens_on_user_id  (user_id)
#  index_access_tokens_on_value    (value) UNIQUE
#

require 'test_helper'

class AccessTokenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
