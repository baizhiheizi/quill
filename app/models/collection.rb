# frozen_string_literal: true

# == Schema Information
#
# Table name: collections
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  state       :string
#  uuid        :uuid
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  author_id   :bigint
#  creator_id  :uuid
#
# Indexes
#
#  index_collections_on_author_id   (author_id)
#  index_collections_on_creator_id  (creator_id)
#  index_collections_on_uuid        (uuid) UNIQUE
#
class Collection < ApplicationRecord
end
