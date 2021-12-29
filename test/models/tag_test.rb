# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id                :integer          not null, primary key
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  articles_count    :integer          default("0")
#  subscribers_count :integer          default("0")
#

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
