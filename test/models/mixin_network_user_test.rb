# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_users
#
#  id            :bigint           not null, primary key
#  encrypted_pin :string
#  name          :string
#  owner_type    :string
#  pin           :string
#  pin_token     :string
#  private_key   :string
#  raw           :json
#  type          :string
#  uuid          :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  session_id    :uuid
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
