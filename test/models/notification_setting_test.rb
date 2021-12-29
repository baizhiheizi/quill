# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  webhook            :jsonb            default("\"{}\"")
#  article_published  :jsonb            default("\"{}\"")
#  article_bought     :jsonb            default("\"{}\"")
#  article_rewarded   :jsonb            default("\"{}\"")
#  comment_created    :jsonb            default("\"{}\"")
#  tagging_created    :jsonb            default("\"{}\"")
#  transfer_processed :jsonb            default("\"{}\"")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
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
