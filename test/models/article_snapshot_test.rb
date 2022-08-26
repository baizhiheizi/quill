# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  raw          :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_article_snapshots_on_article_uuid  (article_uuid)
#

require 'test_helper'

class ArticleSnapshotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
