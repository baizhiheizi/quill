# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  avatar_url :string
#  mixin_uuid :uuid
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mixin_id   :string
#
# Indexes
#
#  index_users_on_mixin_id    (mixin_id) UNIQUE
#  index_users_on_mixin_uuid  (mixin_uuid) UNIQUE
#
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
