# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id           :integer          not null, primary key
#  message_type :string
#  content      :text
#  state        :string
#  delivered_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
