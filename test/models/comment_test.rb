# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  commentable_type :string
#  content          :string
#  deleted_at       :datetime
#  downvotes_count  :integer          default(0)
#  upvotes_count    :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  author_id        :bigint
#  commentable_id   :bigint
#
# Indexes
#
#  index_comments_on_author_id                            (author_id)
#  index_comments_on_commentable_type_and_commentable_id  (commentable_type,commentable_id)
#
require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
