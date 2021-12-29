# frozen_string_literal: true

# == Schema Information
#
# Table name: taggings
#
#  id         :integer          not null, primary key
#  tag_id     :integer
#  article_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_taggings_on_article_id             (article_id)
#  index_taggings_on_tag_id                 (tag_id)
#  index_taggings_on_tag_id_and_article_id  (tag_id,article_id) UNIQUE
#

require 'test_helper'

class TaggingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
