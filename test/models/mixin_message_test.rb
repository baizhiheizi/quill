# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_messages
#
#  id                      :bigint           not null, primary key
#  action                  :string
#  category                :string
#  content(decrepted data) :string
#  processed_at            :datetime
#  raw                     :json
#  state                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  conversation_id         :uuid
#  message_id              :uuid
#  user_id                 :uuid
#
# Indexes
#
#  index_mixin_messages_on_message_id  (message_id) UNIQUE
#
require 'test_helper'

class MixinMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
