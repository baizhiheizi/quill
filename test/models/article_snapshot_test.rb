# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  file_content :text
#  file_hash    :string
#  raw          :json
#  requested_at :datetime
#  signed_at    :datetime
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tx_id        :string
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
