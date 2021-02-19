# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id           :bigint           not null, primary key
#  deleted_at   :datetime
#  last_request :jsonb
#  memo         :string
#  value        :uuid
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint
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
