# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_users
#
#  id            :integer          not null, primary key
#  owner_type    :string
#  owner_id      :integer
#  uuid          :uuid
#  name          :string
#  session_id    :uuid
#  pin_token     :string
#  raw           :json
#  private_key   :string
#  encrypted_pin :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_mixin_network_users_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_mixin_network_users_on_uuid                     (uuid) UNIQUE
#

require 'test_helper'

class MixinNetworkUserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
