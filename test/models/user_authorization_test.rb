# frozen_string_literal: true

# == Schema Information
#
# Table name: user_authorizations
#
#  id                                  :bigint           not null, primary key
#  access_token                        :string
#  provider(third party auth provider) :integer
#  public_key                          :string
#  raw(third pary user info)           :json
#  uid(third party user id)            :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  user_id                             :bigint
#
# Indexes
#
#  index_user_authorizations_on_provider_and_uid  (provider,uid) UNIQUE
#  index_user_authorizations_on_user_id           (user_id)
#

require 'test_helper'

class UserAuthorizationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
