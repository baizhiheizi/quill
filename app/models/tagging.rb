# frozen_string_literal: true

# == Schema Information
#
# Table name: taggings
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint
#  tag_id     :bigint
#
# Indexes
#
#  index_taggings_on_article_id             (article_id)
#  index_taggings_on_tag_id                 (tag_id)
#  index_taggings_on_tag_id_and_article_id  (tag_id,article_id) UNIQUE
#
class Tagging < ApplicationRecord
  belongs_to :tag, counter_cache: :articles_count
  belongs_to :article, counter_cache: :tags_count
end
