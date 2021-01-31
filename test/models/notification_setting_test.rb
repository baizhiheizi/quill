# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id                 :bigint           not null, primary key
#  article_bought     :jsonb
#  article_published  :jsonb
#  article_rewarded   :jsonb
#  comment_created    :jsonb
#  tagging_created    :jsonb
#  transfer_processed :jsonb
#  webhook            :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id)
#
require 'test_helper'

class NotificationSettingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
