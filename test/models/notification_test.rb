# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id             :integer          not null, primary key
#  recipient_type :string           not null
#  recipient_id   :integer          not null
#  type           :string           not null
#  params         :jsonb
#  read_at        :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_notifications_on_read_at    (read_at)
#  index_notifications_on_recipient  (recipient_type,recipient_id)
#

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
