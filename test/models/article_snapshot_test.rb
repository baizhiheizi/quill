# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :integer          not null, primary key
#  article_uuid :uuid
#  raw          :json
#  file_hash    :string
#  tx_id        :string
#  file_content :text
#  state        :string
#  requested_at :datetime
#  signed_at    :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_article_snapshots_on_article_uuid  (article_uuid)
#  index_article_snapshots_on_tx_id         (tx_id) UNIQUE
#

require 'test_helper'

class ArticleSnapshotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
