# frozen_string_literal: true

# == Schema Information
#
# Table name: user_access_tokens
#
#  id         :bigint           not null, primary key
#  memo       :string           not null
#  value      :uuid
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_user_access_tokens_on_user_id  (user_id)
#  index_user_access_tokens_on_value    (value) UNIQUE
#
require 'test_helper'

class UserAccessTokenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
