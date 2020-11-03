# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  commentable_type :string
#  content          :string
#  deleted_at       :datetime
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
class Comment < ApplicationRecord
  include SoftDeletable

  belongs_to :author, class_name: 'User', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true

  validates :content, presence: true, length: { maximum: 1000 }
end
