# frozen_string_literal: true

# == Schema Information
#
# Table name: article_snapshots
#
#  id           :bigint           not null, primary key
#  article_uuid :uuid
#  block_number :integer
#  file_hash    :string
#  raw          :json
#  signature    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_article_snapshots_on_block_number  (block_number) UNIQUE
#
class ArticleSnapshot < ApplicationRecord
end
